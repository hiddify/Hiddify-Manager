"""Tests for utils/certs.py — the cryptography-based self-signed cert path."""
import os
from datetime import datetime, timedelta, timezone
from unittest.mock import patch

from cryptography import x509
from cryptography.hazmat.primitives import serialization

from hiddify_manager.utils import certs


def _read_cert(path):
    with open(path, "rb") as f:
        return x509.load_pem_x509_certificate(f.read())


def test_ensure_creates_files_when_missing(tmp_path):
    cert, key = certs.ensure_self_signed_cert("example.com", str(tmp_path))
    assert cert == str(tmp_path / "example.com.crt")
    assert key == str(tmp_path / "example.com.crt.key")
    assert os.path.exists(cert) and os.path.exists(key)


def test_cert_has_expected_subject(tmp_path):
    certs.ensure_self_signed_cert("foo.example.com", str(tmp_path))
    cert = _read_cert(str(tmp_path / "foo.example.com.crt"))
    cn = cert.subject.get_attributes_for_oid(x509.NameOID.COMMON_NAME)
    assert cn[0].value == "foo.example.com"
    org = cert.subject.get_attributes_for_oid(x509.NameOID.ORGANIZATION_NAME)
    # Matches the legacy openssl -subj "/O=Google Trust Services LLC/..."
    assert org[0].value == "Google Trust Services LLC"


def test_key_is_rsa_2048(tmp_path):
    certs.ensure_self_signed_cert("example.com", str(tmp_path))
    with open(tmp_path / "example.com.crt.key", "rb") as f:
        key = serialization.load_pem_private_key(f.read(), password=None)
    assert key.key_size == 2048
    # And the file is locked down
    assert oct((tmp_path / "example.com.crt.key").stat().st_mode)[-3:] == "600"


def test_idempotent_when_cert_valid(tmp_path):
    """A second call with valid files should NOT regenerate them."""
    certs.ensure_self_signed_cert("example.com", str(tmp_path))
    first_serial = _read_cert(str(tmp_path / "example.com.crt")).serial_number
    certs.ensure_self_signed_cert("example.com", str(tmp_path))
    second_serial = _read_cert(str(tmp_path / "example.com.crt")).serial_number
    assert first_serial == second_serial


def test_regenerates_when_cert_expired(tmp_path):
    # Generate "in the past"
    with patch.object(certs, "_now", return_value=datetime(2000, 1, 1, tzinfo=timezone.utc)):
        certs.ensure_self_signed_cert("example.com", str(tmp_path))
    old_serial = _read_cert(str(tmp_path / "example.com.crt")).serial_number
    # Run "now" — past cert has expired, expect fresh cert
    certs.ensure_self_signed_cert("example.com", str(tmp_path))
    new_serial = _read_cert(str(tmp_path / "example.com.crt")).serial_number
    assert old_serial != new_serial


def test_regenerates_when_cert_unreadable(tmp_path):
    (tmp_path / "example.com.crt").write_text("not a real cert\n")
    (tmp_path / "example.com.crt.key").write_bytes(b"")
    certs.ensure_self_signed_cert("example.com", str(tmp_path))
    # Should now be a real cert
    _read_cert(str(tmp_path / "example.com.crt"))


def test_regenerates_when_key_invalid(tmp_path):
    # Valid cert, garbage key
    certs.ensure_self_signed_cert("example.com", str(tmp_path))
    (tmp_path / "example.com.crt.key").write_bytes(b"\x00\x01\x02")
    certs.ensure_self_signed_cert("example.com", str(tmp_path))
    # Now the key parses
    with open(tmp_path / "example.com.crt.key", "rb") as f:
        serialization.load_pem_private_key(f.read(), password=None)


def test_long_domain_truncates_cn(tmp_path):
    long_domain = "a" * 70 + ".example.com"
    cert_path, _ = certs.ensure_self_signed_cert(long_domain, str(tmp_path))
    cert = _read_cert(cert_path)
    cn = cert.subject.get_attributes_for_oid(x509.NameOID.COMMON_NAME)[0].value
    assert len(cn) == certs.MAX_DOMAIN_LEN
    # File path still uses the full domain (matches legacy behaviour)
    assert long_domain in cert_path


def test_creates_ssl_dir_if_missing(tmp_path):
    target = tmp_path / "deep" / "ssl"
    cert, key = certs.ensure_self_signed_cert("example.com", str(target))
    assert os.path.isdir(target)
    assert os.path.exists(cert)


def test_not_before_tolerates_clock_skew(tmp_path):
    """Legacy openssl used the current time; we backdate ~1m to tolerate
    a small skew between this machine and clients verifying the cert."""
    certs.ensure_self_signed_cert("example.com", str(tmp_path))
    cert = _read_cert(str(tmp_path / "example.com.crt"))
    nbf = getattr(cert, "not_valid_before_utc", None) or cert.not_valid_before.replace(tzinfo=timezone.utc)
    now = datetime.now(timezone.utc)
    assert nbf <= now
    # And less than 5 minutes in the past
    assert (now - nbf) < timedelta(minutes=5)
