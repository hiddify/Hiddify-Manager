"""
Real-ACME certificate acquisition for a single domain.

Ports the orchestration in acme.sh/cert_utils.sh::get_cert: resolve the
domain, decide which ACME server / flags to use, drive the bundled
acme.sh binary to actually do the challenge, install the resulting
cert + key into ssl/, and fall back to a self-signed cert if anything
fails.

The acme.sh binary itself stays (real ACME client; no good drop-in
Python alternative without taking on certbot's massive dep tree).
Everything around it — dig, the per-IP-type branching, the LE→ZeroSSL
fallback, the restricted-TLD check, install + reload, the
fall-back-to-self-signed — is python now.
"""
import ipaddress
import os
import socket
import sys

from hiddify_manager.utils.certs import ensure_self_signed_cert
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import PROJECT_ROOT
from hiddify_manager.utils.shell import run_cmd


SSL_DIR = os.path.join(PROJECT_ROOT, "ssl")
ACME_DIR = os.path.join(PROJECT_ROOT, "acme.sh")
ACME_BIN = os.path.join(ACME_DIR, "lib", "acme.sh")
WEBROOT = os.path.join(ACME_DIR, "www")
ACME_LOG = os.path.join(PROJECT_ROOT, "log", "system", "acme.log")
PREPARE_HOOK = os.path.join(ACME_DIR, "prepare_acme.sh")
NGINX_ACME_CONF = os.path.join(PROJECT_ROOT, "nginx", "parts", "acme.conf")

MAX_DOMAIN_LEN = 64

# Same list as cert_utils.sh: TLDs that ZeroSSL's policy doesn't accept.
RESTRICTED_TLDS = frozenset({
    "af", "by", "cu", "er", "gn", "ir", "kp", "lr", "ru", "ss", "su",
    "sy", "zw", "amazonaws.com", "azurewebsites.net", "cloudapp.net",
})


def _is_ip(domain):
    """Return 4 for IPv4 literal, 6 for IPv6 literal, None for a hostname."""
    try:
        addr = ipaddress.ip_address(domain)
        return addr.version
    except ValueError:
        return None


def _is_zerossl_ok(domain):
    domain = domain.lower()
    for tld in RESTRICTED_TLDS:
        if domain.endswith("." + tld):
            return False
    return True


def _resolve(domain, family):
    """Best-effort DNS lookup. Returns the first address or '' on failure."""
    try:
        infos = socket.getaddrinfo(domain, None, family=family)
    except (socket.gaierror, OSError):
        return ""
    for info in infos:
        return info[4][0]
    return ""


def _public_ip(version):
    """Mirror set_config_from_hpanel's `curl https://v4.ident.me`-style probe."""
    url = "https://v6.ident.me/" if version == 6 else "https://v4.ident.me/"
    res = run_cmd(
        ["curl", "--connect-timeout", "2", "-s", url],
        check=False, capture_output=True,
    )
    return (res.stdout or "").strip()


def _acmecmd(extra_args):
    """Equivalent of the legacy acmecmd() in cert_utils.sh."""
    base = [
        ACME_BIN, "--issue",
        "-w", WEBROOT,
        "--log", ACME_LOG,
        "--pre-hook", f"bash {PREPARE_HOOK}",
    ]
    os.makedirs(os.path.dirname(ACME_LOG), exist_ok=True)
    return run_cmd(base + list(extra_args), cwd=ACME_DIR, check=False)


def _try_issue(domain, ip_version):
    """
    Drive the acme.sh CLI to issue a cert. Returns 0 on success, non-zero on
    failure. Branches per IP-version like the bash did.
    """
    if ip_version == 4:
        # Short-lived LE profile for direct IP issuance.
        return _acmecmd([
            "-d", domain, "--server", "letsencrypt",
            "--certificate-profile", "shortlived", "--days", "6",
        ]).returncode
    if ip_version == 6:
        return _acmecmd([
            "-d", f"[{domain}]", "--server", "letsencrypt",
            "--certificate-profile", "shortlived", "--days", "6",
            "--listen-v6",
        ]).returncode

    # Plain hostname: try LE; fall back to ZeroSSL when the TLD isn't on
    # ZeroSSL's blocklist.
    rc = _acmecmd(["-d", domain, "--server", "letsencrypt"]).returncode
    if rc != 0 and _is_zerossl_ok(domain):
        log.info(f"cert_issuer: LE failed for {domain}, retrying via ZeroSSL")
        rc = _acmecmd(["-d", domain, "--server", "zerossl"]).returncode
    return rc


def _install_cert(domain):
    """`acme.sh --installcert` into ssl/<domain>.crt + .crt.key."""
    cert_path = os.path.join(SSL_DIR, f"{domain}.crt")
    key_path = os.path.join(SSL_DIR, f"{domain}.crt.key")
    os.makedirs(SSL_DIR, exist_ok=True)
    return run_cmd(
        [
            ACME_BIN, "--installcert", "-d", domain,
            "--fullchainpath", cert_path,
            "--keypath", key_path,
            "--reloadcmd", "echo success",
        ],
        cwd=ACME_DIR, check=False,
    ).returncode


def _stop_nginx_acme():
    """Mirror cert_utils.sh::stop_nginx_acme: empty acme.conf + reload."""
    try:
        with open(NGINX_ACME_CONF, "w") as f:
            f.write("")
    except OSError as e:
        log.warning(f"cert_issuer: could not clear {NGINX_ACME_CONF}: {e}")
    run_cmd(["systemctl", "reload", "--now", "hiddify-nginx"], check=False)
    run_cmd(["systemctl", "reload", "hiddify-haproxy"], check=False)


def _lockdown(domain):
    """Match legacy: chmod 600 on the per-domain key and the ssl/ tree."""
    key = os.path.join(SSL_DIR, f"{domain}.crt.key")
    if os.path.exists(key):
        os.chmod(key, 0o600)
    if os.path.isdir(SSL_DIR):
        for name in os.listdir(SSL_DIR):
            try:
                os.chmod(os.path.join(SSL_DIR, name), 0o600)
            except OSError:
                pass


def get_cert(domain):
    """
    Top-level: issue + install a real cert for `domain`; on any failure,
    drop a self-signed one so haproxy/nginx still have something to serve.

    Returns True if a real cert was issued, False if we fell back to
    self-signed (or if the domain was rejected outright).
    """
    if not domain or len(domain) > MAX_DOMAIN_LEN:
        log.warning(f"cert_issuer: skipping invalid/long domain {domain!r}")
        ensure_self_signed_cert(domain or "invalid", SSL_DIR)
        _lockdown(domain or "")
        return False

    ip_version = _is_ip(domain)
    if ip_version is None:
        v4 = _resolve(domain, socket.AF_INET)
        v6 = _resolve(domain, socket.AF_INET6)
        server_v4 = _public_ip(4)
        server_v6 = _public_ip(6)
        log.info(
            f"cert_issuer: {domain} resolves to v4={v4!r} v6={v6!r}; "
            f"server v4={server_v4!r} v6={server_v6!r}"
        )
        if (not server_v4 or v4 != server_v4) and (not server_v6 or v6 != server_v6):
            log.warning(
                f"cert_issuer: {domain} doesn't resolve to this server; "
                "ACME will probably fail but trying anyway"
            )

    rc = _try_issue(domain, ip_version)
    if rc == 0:
        rc = _install_cert(domain)

    if rc != 0:
        log.warning(
            f"cert_issuer: ACME flow exited {rc}; falling back to self-signed"
        )
        ensure_self_signed_cert(domain, SSL_DIR)
        _lockdown(domain)
        _stop_nginx_acme()
        return False

    _lockdown(domain)
    _stop_nginx_acme()
    return True


def main():
    """CLI entry. `python -m hiddify_manager.modules.cert_issuer <domain>`."""
    if len(sys.argv) < 2:
        log.error("usage: cert_issuer <domain>")
        return 2
    ok = get_cert(sys.argv[1])
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
