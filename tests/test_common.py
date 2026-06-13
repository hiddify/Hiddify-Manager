"""Tests for the post-panel logic in hiddify_manager.modules.common.

Focus on the pure helpers (port enumeration, MOTD audit, timezone
choice) — the firewall mutations are exercised in test_firewall.py.
"""
import os
from unittest.mock import patch, call

import pytest

from hiddify_manager.modules import common


# ---- helpers ---------------------------------------------------------------

def test_split_csv_ports_handles_blanks_and_garbage():
    assert common._split_csv_ports("80, 443,, 8443") == [80, 443, 8443]
    assert common._split_csv_ports("") == []
    assert common._split_csv_ports(None) == []
    # garbage entries skipped, not raised
    assert common._split_csv_ports("80,notaport,443") == [80, 443]


# ---- timezone --------------------------------------------------------------

@pytest.mark.parametrize("country, expected", [
    ("cn", "Asia/Shanghai"),
    ("ru", "Europe/Moscow"),
    ("CN", "Asia/Shanghai"),  # case-insensitive
    ("de", "Asia/Tehran"),    # default
    ("", "Asia/Tehran"),
])
def test_apply_timezone_picks_right_tz(country, expected):
    cfg = {"hconfigs": {"country": country}}
    # Pretend the system is currently on UTC so the change actually runs.
    fake = type("R", (), {"returncode": 0, "stdout": "UTC\n"})
    with patch.object(common, "run_cmd", return_value=fake) as mock_run, \
         patch.dict(os.environ, {"MODE": ""}, clear=False):
        common._apply_timezone(cfg)
    calls = [c.args[0] for c in mock_run.call_args_list if "set-timezone" in c.args[0]]
    assert calls == [["timedatectl", "set-timezone", expected]]


def test_apply_timezone_noop_when_already_correct():
    cfg = {"hconfigs": {"country": "ir"}}
    fake = type("R", (), {"returncode": 0, "stdout": "Asia/Tehran\n"})
    with patch.object(common, "run_cmd", return_value=fake) as mock_run, \
         patch.dict(os.environ, {"MODE": ""}, clear=False):
        common._apply_timezone(cfg)
    # Only the `show` invocation, no set-timezone or mariadb restart.
    actions = [c.args[0][0:2] for c in mock_run.call_args_list]
    assert all(a != ["timedatectl", "set-timezone"] for a in actions)


def test_apply_timezone_skipped_in_docker():
    cfg = {"hconfigs": {"country": "cn"}}
    with patch.object(common, "run_cmd") as mock_run, \
         patch.dict(os.environ, {"MODE": "docker"}, clear=False):
        common._apply_timezone(cfg)
    mock_run.assert_not_called()


# ---- port enumeration ------------------------------------------------------

def test_apply_ports_enumerates_all_categories():
    cfg = {
        "hconfigs": {
            "wireguard_port": 51820,
            "shadowsocks2022_enable": True,
            "shadowsocks2022_port": 4443,
            "mieru_enable": True,
            "mieru_tcp_ports": "5000, 5001",
            "mieru_udp_ports": "5100",
            "tls_ports": "443, 8443",
            "http_ports": "80",
            "ssh_server_port": 2200,
            "ssh_server_enable": True,
        },
        "domains": [
            {"internal_port_hysteria2": 0, "internal_port_tuic": 6000, "internal_port_naive": 7000},
            {"internal_port_hysteria2": 8000, "internal_port_tuic": 0, "internal_port_naive": 0},
        ],
    }
    with patch.object(common.firewall, "allow_port") as ap, \
         patch.object(common.firewall, "remove_port") as rp:
        common._apply_ports(cfg)

    opened = {(c.args[0], c.args[1]) for c in ap.call_args_list}
    # fixed
    assert ("tcp", 22) in opened
    assert ("tcp", 443) in opened
    assert ("udp", 443) in opened
    # dynamic
    assert ("udp", 51820) in opened          # wireguard
    assert ("tcp", 4443) in opened           # ss2022
    assert ("udp", 4443) in opened
    assert ("udp", 6000) in opened           # tuic on domain[0]
    assert ("udp", 7000) in opened           # naive on domain[0]
    assert ("udp", 8000) in opened           # hysteria2 on domain[1]
    # mieru
    assert ("tcp", 5000) in opened
    assert ("tcp", 5001) in opened
    assert ("udp", 5100) in opened
    # tls + http
    assert ("tcp", 8443) in opened
    assert ("tcp", 80) in opened             # http_ports
    assert ("udp", 8443) in opened           # tls also opens udp
    # ssh server
    assert ("tcp", 2200) in opened
    rp.assert_not_called()


def test_apply_ports_removes_ssh_server_port_when_disabled():
    cfg = {
        "hconfigs": {
            "ssh_server_port": 2200,
            "ssh_server_enable": False,
        },
        "domains": [],
    }
    with patch.object(common.firewall, "allow_port"), \
         patch.object(common.firewall, "remove_port") as rp:
        common._apply_ports(cfg)
    rp.assert_called_once_with("tcp", 2200)


def test_apply_ports_skips_disabled_optional_blocks():
    """Without shadowsocks2022_enable / mieru_enable, those ports aren't opened."""
    cfg = {
        "hconfigs": {
            "shadowsocks2022_port": 4443,  # set but not enabled
            "mieru_tcp_ports": "5000",      # set but not enabled
            "tls_ports": "",
            "http_ports": "",
        },
        "domains": [],
    }
    with patch.object(common.firewall, "allow_port") as ap, \
         patch.object(common.firewall, "remove_port"):
        common._apply_ports(cfg)
    opened = {(c.args[0], c.args[1]) for c in ap.call_args_list}
    assert ("tcp", 4443) not in opened
    assert ("tcp", 5000) not in opened
    # but fixed ports still opened
    assert ("tcp", 443) in opened


# ---- sshd audit ------------------------------------------------------------

def test_audit_sshd_writes_motd_when_password_auth_allowed(tmp_path, monkeypatch):
    sshd = tmp_path / "sshd_config"
    sshd.write_text("# default\n#PasswordAuthentication yes\nPort 22\n")
    motd = tmp_path / "motd"
    motd.write_text("Welcome\n")

    monkeypatch.setattr(common, "_glob_sshd_includes", lambda: [str(sshd)])
    with patch("builtins.open", side_effect=open) as _, \
         patch.object(common, "run_cmd"):
        # Patch the well-known paths to our tmp_path versions.
        original_open = open
        def open_proxy(path, *a, **kw):
            if path == "/etc/ssh/sshd_config":
                return original_open(str(sshd), *a, **kw)
            if path == "/etc/motd":
                return original_open(str(motd), *a, **kw)
            return original_open(path, *a, **kw)
        with patch("builtins.open", side_effect=open_proxy):
            common._audit_sshd_password_auth()
    assert "Your server is vulnerable" in motd.read_text()


def test_audit_sshd_removes_motd_when_password_auth_disabled(tmp_path):
    sshd = tmp_path / "sshd_config"
    sshd.write_text("PasswordAuthentication no\n")
    motd = tmp_path / "motd"
    motd.write_text(
        "Welcome\n"
        "Hiddify! Your server is vulnerable to abuses ...\n"
        "Other line\n"
    )

    with patch.object(common, "_glob_sshd_includes", return_value=[str(sshd)]), \
         patch.object(common, "run_cmd"):
        original_open = open
        def open_proxy(path, *a, **kw):
            if path == "/etc/ssh/sshd_config":
                return original_open(str(sshd), *a, **kw)
            if path == "/etc/motd":
                return original_open(str(motd), *a, **kw)
            return original_open(path, *a, **kw)
        with patch("builtins.open", side_effect=open_proxy):
            common._audit_sshd_password_auth()
    out = motd.read_text()
    assert "Your server is vulnerable" not in out
    assert "Welcome" in out
    assert "Other line" in out


# ---- auto update cron ------------------------------------------------------

def test_apply_auto_update_cron_writes_when_enabled(tmp_path):
    cfg = {"hconfigs": {"auto_update": True}}
    cron_path = tmp_path / "hiddify_auto_update"
    with patch.object(common, "run_cmd"), \
         patch("os.remove"):
        original_open = open
        def open_proxy(path, *a, **kw):
            if path == "/etc/cron.d/hiddify_auto_update":
                return original_open(str(cron_path), *a, **kw)
            return original_open(path, *a, **kw)
        with patch("builtins.open", side_effect=open_proxy):
            common._apply_auto_update_cron(cfg)
    assert cron_path.exists()
    assert "init.sh update" in cron_path.read_text()


def test_apply_auto_update_cron_removes_when_disabled(tmp_path):
    cfg = {"hconfigs": {"auto_update": False}}
    cron_path = tmp_path / "hiddify_auto_update"
    cron_path.write_text("existing\n")
    with patch.object(common, "run_cmd"):
        with patch("os.remove") as rm:
            common._apply_auto_update_cron(cfg)
            rm.assert_called_once_with("/etc/cron.d/hiddify_auto_update")
