"""
Replaces common/install.sh: the system bootstrap that runs before any
service module. Installs base apt packages, sets up the hiddify-common
group, applies sysctl tuning, toggles IPv6 per ONLY_IPV4, writes cron
entries, sets locale, and disables rpcbind.
"""
import os
import shutil

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import COMMON_DIR, PROJECT_ROOT, LOG_DIR
from hiddify_manager.utils.shell import run_cmd


APT_BASE_PACKAGES = [
    "apt-transport-https", "apt-utils", "at", "build-essential",
    "ca-certificates", "cron", "curl", "default-libmysqlclient-dev",
    "dnsutils", "gawk", "git", "gnupg-agent", "gnupg2", "iproute2",
    "iptables", "jq", "less", "libev-dev", "libevdev2", "libssl-dev",
    "locales", "lsb-release", "lsof", "pkg-config", "qrencode",
    "software-properties-common", "sudo", "ubuntu-keyring", "wget",
    "whiptail",
]
APT_REMOVE_PACKAGES = ["apache2", "needrestart", "needrestart-session"]
EXCLUDED_IFACES = {"warp", "lo"}


def _apt_install(packages):
    run_cmd(
        ["apt-get", "install", "-y", "--no-install-recommends", *packages],
        check=False,
    )


def _apt_remove(packages):
    for pkg in packages:
        # Cheap installed-check: dpkg -s exits 0 only if installed.
        res = run_cmd(["dpkg", "-s", pkg], check=False, capture_output=True)
        if res.returncode == 0:
            run_cmd(["apt-get", "remove", "-y", "--auto-remove", pkg], check=False)


def _iface_names():
    res = run_cmd(["ip", "-o", "link", "show"], check=False, capture_output=True)
    if res.returncode != 0 or not res.stdout:
        return []
    names = []
    for line in res.stdout.splitlines():
        # Format: "1: lo: <LOOPBACK,UP,LOWER_UP> ..."
        parts = line.split(":")
        if len(parts) >= 2:
            name = parts[1].strip().split("@")[0]
            if name and name.replace("_", "").isalnum():
                names.append(name)
    return names


def _toggle_ipv6(only_ipv4):
    stat = "1" if only_ipv4 else "0"
    label = "Disable" if only_ipv4 else "Enable"

    if not only_ipv4:
        for k in ("all", "default", "lo"):
            run_cmd(["sysctl", "-w", f"net.ipv6.conf.{k}.disable_ipv6=0"], check=False)

    for iface in _iface_names():
        if iface in EXCLUDED_IFACES:
            continue
        res = run_cmd(
            ["sysctl", "-q", "-w", f"net.ipv6.conf.{iface}.disable_ipv6={stat}"],
            check=False,
        )
        log.info(f"IPv6 {label}d for {iface}" if res.returncode == 0
                 else f"Failed to {label} IPv6 for {iface}")


def _write_cron_entries():
    reboot_cron = "/etc/cron.d/hiddify_reinstall_on_reboot"
    daily_cron = "/etc/cron.d/hiddify_daily"
    legacy = "/etc/cron.d/hiddify_daily_memory_release"

    with open(reboot_cron, "w") as f:
        f.write(
            "@reboot root /opt/hiddify-manager/init.sh install "
            ">> /opt/hiddify-manager/log/system/reboot.log 2>&1\n"
        )

    # One-shot legacy filename migration; ignore if already gone.
    if os.path.exists(legacy) and not os.path.exists(daily_cron):
        try:
            shutil.move(legacy, daily_cron)
        except OSError as e:
            log.warning(f"cron migration mv failed: {e}")
    elif os.path.exists(legacy):
        try:
            os.remove(legacy)
        except OSError:
            pass

    with open(daily_cron, "w") as f:
        f.write(
            "@daily root /opt/hiddify-manager/common/daily_actions.sh "
            ">> /opt/hiddify-manager/log/system/daily_actions.log 2>&1\n"
        )

    run_cmd(["service", "cron", "reload"], check=False)


def install():
    os.makedirs(LOG_DIR, exist_ok=True)

    _apt_remove(APT_REMOVE_PACKAGES)
    _apt_install(APT_BASE_PACKAGES)

    run_cmd(["groupadd", "-f", "hiddify-common"], check=False)
    run_cmd(["usermod", "-aG", "hiddify-common", "root"], check=False)

    run_cmd(["systemctl", "unmask", "--now", "systemd-resolved.service"], check=False)
    run_cmd(["systemctl", "enable", "--now", "systemd-resolved"], check=False)

    sysctl_src = os.path.join(COMMON_DIR, "sysctl.conf")
    sysctl_dst = "/etc/sysctl.d/hiddify.conf"
    if os.path.exists(sysctl_src):
        run_cmd(["ln", "-sf", sysctl_src, sysctl_dst], check=False)

    if os.environ.get("MODE") != "docker":
        run_cmd(["sysctl", "--system"], check=False, capture_output=True)

    only_ipv4 = os.environ.get("ONLY_IPV4", "").lower() == "true"
    if not only_ipv4:
        # Probe whether IPv6 actually works; if not, force-disable.
        probe = run_cmd(
            ["curl", "--connect-timeout", "1", "-s", "http://ipv6.google.com"],
            check=False, capture_output=True,
        )
        if probe.returncode != 0:
            only_ipv4 = True
    _toggle_ipv6(only_ipv4)

    bbr = os.path.join(COMMON_DIR, "google-bbr.sh")
    if os.path.exists(bbr):
        run_cmd(["bash", bbr], cwd=COMMON_DIR, check=False, capture_output=True)

    _write_cron_entries()

    if os.environ.get("MODE") != "docker":
        run_cmd(["localectl", "set-locale", "LANG=C.UTF-8"], check=False)
    run_cmd(["update-locale", "LANG=C.UTF-8"], check=False)

    with open("/etc/sudoers.d/hiddify", "w") as f:
        f.write(
            "hiddify-panel ALL=(root) NOPASSWD: "
            "/opt/hiddify-manager/common/commander.py\n"
        )
    os.chmod("/etc/sudoers.d/hiddify", 0o440)

    menu_sh = os.path.join(PROJECT_ROOT, "menu.sh")
    if os.path.exists(menu_sh):
        run_cmd(["ln", "-sf", menu_sh, "/usr/bin/hiddify"], check=False)

    for unit in ("rpcbind.socket", "rpcbind"):
        run_cmd(["systemctl", "disable", "--now", unit], check=False)
