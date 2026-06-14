"""
Self-signed certificate generation via the `cryptography` library.

Replaces acme.sh/generate_self_signed_cert.sh + the `get_self_signed_cert`
bash function in acme.sh/cert_utils.sh: no openssl shell-outs, no acme.sh
binary, just the standard pyca/cryptography API that's already a transitive
dep of hiddifypanel.

ensure_self_signed_cert(domain, ssl_dir) is the entry point used by
manager._render_all_templates after the panel produces current.json,
so haproxy/nginx have *something* to bind their TLS frontends to before
real certs land via the ACME flow.
"""
import os
from datetime import datetime, timedelta, timezone

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, rsa
from cryptography.x509.oid import NameOID

from hiddify_manager.utils.logger import log


# Match the legacy subject (so any tool inspecting an existing cert sees
# the same DN). The Common Name swaps in the requested domain.
_LEGACY_DN = [
    (NameOID.COUNTRY_NAME, "GB"),
    (NameOID.STATE_OR_PROVINCE_NAME, "London"),
    (NameOID.LOCALITY_NAME, "London"),
    (NameOID.ORGANIZATION_NAME, "Google Trust Services LLC"),
]

# 10-year validity. The cert exists to make haproxy/nginx start; it's
# replaced by a real ACME cert when DNS for the domain resolves to us.
DEFAULT_LIFETIME = timedelta(days=3650)
MAX_DOMAIN_LEN = 64


def _now():
    """Indirection for tests."""
    return datetime.now(timezone.utc)


def _generate(domain, cert_path, key_path):
    """Write a fresh RSA 2048 keypair + self-signed cert for `domain`."""
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    subject = issuer = x509.Name([
        x509.NameAttribute(oid, val) for oid, val in _LEGACY_DN
    ] + [x509.NameAttribute(NameOID.COMMON_NAME, domain)])
    now = _now()
    cert = (
        x509.CertificateBuilder()
        .subject_name(subject).issuer_name(issuer)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now - timedelta(minutes=1))  # tolerate clock skew
        .not_valid_after(now + DEFAULT_LIFETIME)
        .sign(key, hashes.SHA256())
    )

    with open(cert_path, "wb") as f:
        f.write(cert.public_bytes(serialization.Encoding.PEM))
    with open(key_path, "wb") as f:
        f.write(
            key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.TraditionalOpenSSL,
                encryption_algorithm=serialization.NoEncryption(),
            )
        )
    os.chmod(key_path, 0o600)
    os.chmod(cert_path, 0o644)
    log.info(f"certs: wrote self-signed cert for {domain}")


def _cert_expired_or_invalid(cert_path):
    """True if there's no cert there or it's expired."""
    if not os.path.exists(cert_path):
        return True
    try:
        with open(cert_path, "rb") as f:
            cert = x509.load_pem_x509_certificate(f.read())
    except (ValueError, OSError) as e:
        log.info(f"certs: {cert_path} unreadable ({e}); will regenerate")
        return True
    # Older cryptography versions use not_valid_after (naive UTC); newer use
    # not_valid_after_utc (timezone-aware). Try the new attribute first.
    expiry = getattr(cert, "not_valid_after_utc", None)
    if expiry is None:
        expiry = cert.not_valid_after.replace(tzinfo=timezone.utc)
    return expiry < _now()


def _key_invalid(key_path):
    """True if the key file is missing, unparseable, or the wrong shape."""
    if not os.path.exists(key_path):
        return True
    try:
        with open(key_path, "rb") as f:
            key = serialization.load_pem_private_key(f.read(), password=None)
    except (ValueError, TypeError, OSError) as e:
        log.info(f"certs: {key_path} unreadable ({e}); will regenerate")
        return True
    return not isinstance(key, (rsa.RSAPrivateKey, ec.EllipticCurvePrivateKey))


def ensure_self_signed_cert(domain, ssl_dir):
    """
    Make sure ssl_dir/<domain>.crt + .crt.key exist, are well-formed, and
    aren't expired. Generate them if any of those isn't true.

    Returns (cert_path, key_path) on success, or (None, None) if the
    domain is too long for a CN (matches legacy's silent skip path).
    """
    if len(domain) > MAX_DOMAIN_LEN:
        log.info(f"certs: domain longer than {MAX_DOMAIN_LEN} chars, truncating CN")
        domain_for_cn = domain[:MAX_DOMAIN_LEN]
    else:
        domain_for_cn = domain

    os.makedirs(ssl_dir, exist_ok=True)
    cert_path = os.path.join(ssl_dir, f"{domain}.crt")
    key_path = os.path.join(ssl_dir, f"{domain}.crt.key")

    if _cert_expired_or_invalid(cert_path) or _key_invalid(key_path):
        _generate(domain_for_cn, cert_path, key_path)
    return cert_path, key_path
