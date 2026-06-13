"""
Cloudflare WARP via wgcf + wg-quick@warp.

Replaces other/warp/install.sh + the warp wireguard run.sh.j2 chain:
download the wgcf binary, register/update a WARP account, generate
the wireguard profile (stripping IPv6 if the host doesn't speak it),
symlink it to /etc/wireguard/warp.conf, and bring up wg-quick@warp.
Verified by probing http://ip-api.com via the warp interface.
"""
import os
import re
import socket

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import module_dir as _module_dir
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.config import hiddify_config
from hiddify_manager.utils.package_manager import download_package


PROFILE = "wgcf-profile.conf"
ACCOUNT = "wgcf-account.toml"
SYS_WARP_CONF = "/etc/wireguard/warp.conf"


def _ipv6_usable():
    """Mirror the legacy probe: false if /proc disables v6 or v6 egress fails."""
    try:
        with open("/proc/sys/net/ipv6/conf/all/disable_ipv6") as f:
            if f.read().strip() == "1":
                return False
    except OSError:
        return False
    res = run_cmd(
        ["curl", "--connect-timeout", "1", "-s", "https://v6.ident.me/"],
        check=False, capture_output=True,
    )
    return res.returncode == 0


def _patch_profile(wg_dir, ipv6_ok):
    """Equivalent to the three sed -i invocations in the legacy run.sh.j2."""
    path = os.path.join(wg_dir, PROFILE)
    if not os.path.exists(path):
        log.error(f"warp: {PROFILE} not produced by wgcf generate")
        return False

    with open(path) as f:
        lines = f.readlines()

    out = []
    for ln in lines:
        # [Peer] -> Table = off\n[Peer]
        if ln.strip() == "[Peer]":
            out.append("Table = off\n")
        # Comment out IPv6 'Address = ...:...' lines when v6 is unusable.
        # Match hex addresses with at least 4 hex chars before ':' (legacy regex).
        if (ln.startswith("Address = ")
                and re.search(r"[0-9a-fA-F]{4,}:", ln)
                and not ipv6_ok):
            ln = "# " + ln
        # Comment out the hardcoded Cloudflare DNS line.
        if "DNS = 1.1.1.1" in ln:
            ln = "# " + ln
        out.append(ln)

    with open(path, "w") as f:
        f.writelines(out)
    return True


def _real_test():
    res = run_cmd(
        ["curl", "-s", "--interface", "warp", "--connect-timeout", "1",
         "http://ip-api.com?fields=message,country,org,query"],
        check=False, capture_output=True,
    )
    if res.returncode == 0:
        log.info(f"WARP probe OK: {res.stdout.strip()[:200]}")
    else:
        log.warning("WARP probe failed")
    return res.returncode == 0


def _wgcf(wg_dir, *args, env=None):
    return run_cmd(
        [os.path.join(wg_dir, "wgcf"), *args],
        cwd=wg_dir, check=False, env=env, capture_output=True,
    )


def _bring_up(wg_dir, env):
    """One pass at registering, generating, and starting wg-quick@warp."""
    account = os.path.join(wg_dir, ACCOUNT)
    if not os.path.exists(account):
        log.info("warp: registering new wgcf account")
        rc = _wgcf(
            wg_dir, "register", "--accept-tos", "-m", "hiddify",
            "-n", socket.gethostname(), env=env,
        )
        if rc.returncode != 0:
            return False

    rc = _wgcf(wg_dir, "update", env=env)
    if rc.returncode != 0:
        log.warning(f"wgcf update failed (rc={rc.returncode})")
        return False

    rc = _wgcf(wg_dir, "generate", env=env)
    if rc.returncode != 0:
        log.warning(f"wgcf generate failed (rc={rc.returncode})")
        return False

    ipv6_ok = _ipv6_usable()
    if not ipv6_ok:
        log.info("warp: IPv6 unusable, will comment out v6 lines in profile")
    if not _patch_profile(wg_dir, ipv6_ok):
        return False

    os.makedirs("/etc/wireguard", exist_ok=True)
    run_cmd(["ln", "-sf", os.path.join(wg_dir, PROFILE), SYS_WARP_CONF], check=False)
    run_cmd(["systemctl", "enable", "wg-quick@warp"], check=False)
    run_cmd(["systemctl", "restart", "wg-quick@warp"], check=False)

    # Give wg-quick a moment to actually install routes before probing —
    # matches the legacy `sleep .5 ; test ; sleep .5 ; test` cadence.
    import time
    time.sleep(0.5)
    if _real_test():
        return True
    time.sleep(0.5)
    return _real_test()


def install():
    base = _module_dir("other/warp")
    wg_dir = os.path.join(base, "wireguard")
    os.makedirs(wg_dir, exist_ok=True)

    run_cmd(["apt-get", "install", "-y", "wireguard-tools"], check=False)

    wgcf_path = os.path.join(wg_dir, "wgcf")
    if download_package("wgcf", wgcf_path):
        os.chmod(wgcf_path, 0o755)
    if not os.path.exists(wgcf_path):
        log.error("warp: wgcf binary missing — aborting")
        return

    # The legacy install.sh disabled the dormant hiddify-warp.service unit.
    run_cmd(["systemctl", "disable", "hiddify-warp.service"], check=False)

    configs = hiddify_config()
    if not configs:
        log.warning("warp: no panel configs available — using empty WGCF_LICENSE_KEY")
        license_key = ""
    else:
        hconfigs = configs.get("hconfigs") or {}
        license_key = hconfigs.get("warp_plus_code") or ""

    account = os.path.join(wg_dir, ACCOUNT)

    # Legacy retry pattern: try with the license key, then back off the
    # account file twice (re-register fresh), finally retry with no key.
    attempts = [license_key, license_key, ""]
    for attempt, key in enumerate(attempts):
        env = dict(os.environ, WGCF_LICENSE_KEY=key)
        if _bring_up(wg_dir, env):
            log.info(f"warp: connected (attempt {attempt + 1})")
            return
        if os.path.exists(account):
            try:
                os.replace(account, account + ".backup")
            except OSError as e:
                log.warning(f"could not back off {ACCOUNT}: {e}")

    log.error("WARP failed to come up after 3 attempts")
