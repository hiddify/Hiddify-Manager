"""Tests for the orchestration in modules/cert_issuer.

We mock run_cmd, socket.getaddrinfo, ensure_self_signed_cert. The point
of these tests is to verify which acme.sh argv shape we hand the binary
per branch, and that the fallback paths run when they should.
"""
import socket
from types import SimpleNamespace
from unittest.mock import patch

import pytest

from hiddify_manager.modules import cert_issuer as ci


def _result(returncode=0, stdout=""):
    return SimpleNamespace(returncode=returncode, stdout=stdout)


@pytest.fixture
def mock_self_signed():
    with patch.object(ci, "ensure_self_signed_cert") as m:
        yield m


@pytest.fixture
def mock_lockdown():
    """Stub _lockdown so we don't chmod random tmpfiles during tests."""
    with patch.object(ci, "_lockdown"):
        yield


@pytest.fixture
def mock_nginx():
    with patch.object(ci, "_stop_nginx_acme"):
        yield


@pytest.fixture(autouse=True)
def mock_prepare_acme(request):
    """
    get_cert calls _prepare_acme(); stub it for tests that don't care.
    Tests with `unmock_prepare_acme` in their fixture list opt out so
    they can exercise the real implementation.
    """
    if "unmock_prepare_acme" in request.fixturenames:
        yield
        return
    with patch.object(ci, "_prepare_acme"):
        yield


@pytest.fixture
def unmock_prepare_acme():
    """Marker fixture — see mock_prepare_acme above."""
    return None


# ---- helpers ---------------------------------------------------------------

def test_is_ip_distinguishes_v4_v6_and_hostname():
    assert ci._is_ip("203.0.113.5") == 4
    assert ci._is_ip("2001:db8::1") == 6
    assert ci._is_ip("example.com") is None


def test_zerossl_blocked_for_restricted_tlds():
    for tld in ("ir", "ru", "sy"):
        assert ci._is_zerossl_ok(f"x.{tld}") is False
    assert ci._is_zerossl_ok("example.com") is True


# ---- _try_issue branches ---------------------------------------------------

def test_try_issue_v4_uses_letsencrypt_shortlived():
    with patch.object(ci, "_acmecmd", return_value=_result(0)) as m:
        rc = ci._try_issue("203.0.113.5", 4)
    assert rc == 0
    args = m.call_args.args[0]
    assert "letsencrypt" in args
    assert "shortlived" in args
    assert "203.0.113.5" in args


def test_try_issue_v6_brackets_address_and_listens_v6():
    with patch.object(ci, "_acmecmd", return_value=_result(0)) as m:
        ci._try_issue("2001:db8::1", 6)
    args = m.call_args.args[0]
    assert "[2001:db8::1]" in args
    assert "--listen-v6" in args


def test_try_issue_hostname_falls_back_to_zerossl_on_le_failure():
    """LE returns nonzero, then ZeroSSL is tried."""
    calls = []
    def fake(args):
        calls.append(args[:])
        return _result(0 if "zerossl" in args else 1)
    with patch.object(ci, "_acmecmd", side_effect=fake):
        rc = ci._try_issue("example.com", None)
    assert rc == 0
    assert len(calls) == 2
    assert "letsencrypt" in calls[0]
    assert "zerossl" in calls[1]


def test_try_issue_hostname_does_not_try_zerossl_for_restricted_tld():
    calls = []
    def fake(args):
        calls.append(args[:])
        return _result(1)
    with patch.object(ci, "_acmecmd", side_effect=fake):
        rc = ci._try_issue("foo.ir", None)
    assert rc == 1
    # Only one attempt — LE; ZeroSSL skipped.
    assert len(calls) == 1
    assert "letsencrypt" in calls[0]


# ---- get_cert end-to-end ---------------------------------------------------

def test_get_cert_success_path(mock_self_signed, mock_lockdown, mock_nginx):
    """LE succeeds, installcert succeeds → True, no self-signed fallback."""
    with patch.object(ci, "_resolve", return_value="1.2.3.4"), \
         patch.object(ci, "_public_ip", return_value="1.2.3.4"), \
         patch.object(ci, "_try_issue", return_value=0), \
         patch.object(ci, "_install_cert", return_value=0):
        assert ci.get_cert("example.com") is True
    mock_self_signed.assert_not_called()


def test_get_cert_falls_back_to_self_signed_on_issue_failure(
    mock_self_signed, mock_lockdown, mock_nginx
):
    with patch.object(ci, "_resolve", return_value="1.2.3.4"), \
         patch.object(ci, "_public_ip", return_value="1.2.3.4"), \
         patch.object(ci, "_try_issue", return_value=1):
        assert ci.get_cert("example.com") is False
    mock_self_signed.assert_called_once()


def test_get_cert_falls_back_when_install_fails(
    mock_self_signed, mock_lockdown, mock_nginx
):
    """Issue succeeds but install fails — still fall back."""
    with patch.object(ci, "_resolve", return_value="1.2.3.4"), \
         patch.object(ci, "_public_ip", return_value="1.2.3.4"), \
         patch.object(ci, "_try_issue", return_value=0), \
         patch.object(ci, "_install_cert", return_value=2):
        assert ci.get_cert("example.com") is False
    mock_self_signed.assert_called_once()


def test_get_cert_warns_when_dns_disagrees_with_server_ip(
    mock_self_signed, mock_lockdown, mock_nginx
):
    """Mismatching DNS shouldn't abort — we still try, just warn."""
    with patch.object(ci, "_resolve", side_effect=["10.0.0.1", "fe80::1"]), \
         patch.object(ci, "_public_ip", side_effect=["1.2.3.4", "2001:db8::1"]), \
         patch.object(ci, "_try_issue", return_value=0), \
         patch.object(ci, "_install_cert", return_value=0), \
         patch.object(ci, "log") as mlog:
        ci.get_cert("example.com")
    # The DNS-disagree warning is emitted
    assert any(
        "doesn't resolve to this server" in (call.args[0] if call.args else "")
        for call in mlog.warning.call_args_list
    )


def test_get_cert_rejects_overlong_domain(mock_self_signed, mock_lockdown, mock_nginx):
    too_long = "a" * 65 + ".example.com"
    assert ci.get_cert(too_long) is False
    mock_self_signed.assert_called_once()


def test_get_cert_handles_ip_literal_skips_dns_resolution(
    mock_self_signed, mock_lockdown, mock_nginx
):
    """An IP literal should NOT invoke socket.getaddrinfo."""
    with patch.object(ci, "_resolve") as m_resolve, \
         patch.object(ci, "_public_ip") as m_pub, \
         patch.object(ci, "_try_issue", return_value=0), \
         patch.object(ci, "_install_cert", return_value=0):
        ci.get_cert("203.0.113.5")
    m_resolve.assert_not_called()
    m_pub.assert_not_called()


def test_resolve_returns_empty_string_on_lookup_failure():
    with patch.object(ci.socket, "getaddrinfo", side_effect=socket.gaierror):
        assert ci._resolve("nope.invalid", socket.AF_INET) == ""


# ---- _prepare_acme ---------------------------------------------------------

def test_prepare_acme_writes_conf_and_restarts_when_missing(tmp_path, unmock_prepare_acme):
    """First call: conf doesn't exist → write it and restart nginx."""
    conf = tmp_path / "acme.conf"
    webroot = tmp_path / "www"
    with patch.object(ci, "NGINX_ACME_CONF", str(conf)), \
         patch.object(ci, "WEBROOT", str(webroot)), \
         patch.object(ci, "run_cmd") as m:
        ci._prepare_acme()
    assert conf.exists()
    assert "acme-challenge" in conf.read_text()
    # nginx restart was invoked
    assert any(c.args[0] == ["systemctl", "restart", "hiddify-nginx"] for c in m.call_args_list)


def test_prepare_acme_skips_restart_when_conf_already_correct(tmp_path, unmock_prepare_acme):
    """Second call with matching conf: NO nginx restart."""
    conf = tmp_path / "acme.conf"
    webroot = tmp_path / "www"
    conf.write_text(ci.ACME_NGINX_BLOCK)
    with patch.object(ci, "NGINX_ACME_CONF", str(conf)), \
         patch.object(ci, "WEBROOT", str(webroot)), \
         patch.object(ci, "run_cmd") as m:
        ci._prepare_acme()
    # chown still runs, but no restart.
    restart_calls = [
        c for c in m.call_args_list
        if c.args[0][:2] == ["systemctl", "restart"]
    ]
    assert restart_calls == []
