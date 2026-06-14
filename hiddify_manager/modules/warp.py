"""
Cloudflare WARP via wgcf + wg-quick@warp.

Replaces other/warp/install.sh + the warp wireguard run.sh.j2 chain:
download the wgcf binary, register/update a WARP account, generate
the wireguard profile (stripping IPv6 if the host doesn't speak it),
symlink it to /etc/wireguard/warp.conf, and bring up wg-quick@warp.
Verified by probing http://ip-api.com via the warp interface.
"""
import os
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


def _strip_v6_from_csv(prefix, line, ipv6_ok):
    """
    wgcf emits Address/DNS lines like `Address = 172.16.0.2/32, 2606:...`.
    If v6 is unusable, drop just the v6 entries (anything containing ':')
    instead of commenting the whole line — that would strand the interface
    with no v4 address and break routing.

    If everything in the list is v6, comment the line so wg-quick doesn't
    error on an empty value.
    """
    if ipv6_ok or not line.startswith(prefix):
        return line
    rest = line[len(prefix):].rstrip("\n")
    entries = [e.strip() for e in rest.split(",") if e.strip()]
    kept = [e for e in entries if ":" not in e]
    if not kept:
        return "# " + line
    return f"{prefix}{', '.join(kept)}\n"


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
        ln = _strip_v6_from_csv("Address = ", ln, ipv6_ok)
        ln = _strip_v6_from_csv("DNS = ", ln, ipv6_ok)
        # Even with v6 working, we don't want to push Cloudflare's
        # resolver onto every client — comment the DNS line entirely.
        if ln.lstrip().startswith("DNS = ") and "1.1.1.1" in ln:
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


def _disable_warp():
    """Tear down wg-quick@warp + the dormant hiddify-warp.service unit."""
    for unit in ("wg-quick@warp", "hiddify-warp.service"):
        run_cmd(["systemctl", "stop", unit], check=False)
        run_cmd(["systemctl", "disable", unit], check=False)


def install():
    configs = hiddify_config() or {}
    hconfigs = configs.get("hconfigs") or {}
    # Legacy: install warp unless hconfigs['warp_mode'] == 'disable'.
    # An absent warp_mode key was treated as "not disabled" → install.
    warp_mode = (hconfigs.get("warp_mode") or "").lower()
    if warp_mode == "disable":
        log.info("warp: warp_mode is 'disable' — stopping wg-quick@warp and skipping install")
        _disable_warp()
        return
    license_key = hconfigs.get("warp_plus_code") or ""

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
