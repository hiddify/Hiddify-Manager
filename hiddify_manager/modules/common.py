"""
Replaces common/install.sh + common/run.sh.j2.

install() is the pre-panel system bootstrap (called from the install
loop with no current.json yet): apt packages, hiddify-common group,
sysctl, IPv6 toggle, cron entries, locale, rpcbind disable.

apply_runtime_config(configs) is the post-panel system configuration
(called by manager.run_install after the panel produces current.json):
country-based timezone, the full INPUT/FORWARD firewall ruleset built
from hconfigs + per-domain ports, SSH PasswordAuthentication audit,
auto-update cron.
"""
import os
import re
import shutil

from hiddify_manager.utils import firewall
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import COMMON_DIR, PROJECT_ROOT, LOG_DIR, VENV_DIR
from hiddify_manager.utils.shell import run_cmd


APT_BASE_PACKAGES = [
    "apt-transport-https", "apt-utils", "at", "build-essential",
    "ca-certificates", "clang", "cron", "curl",
    "default-libmysqlclient-dev", "dnsutils", "gawk", "git",
    "gnupg-agent", "gnupg2", "iproute2", "iptables", "jq", "less",
    "libev-dev", "libevdev2", "libssl-dev", "locales", "lsb-release",
    "lsof", "pkg-config", "qrencode", "software-properties-common",
    "sudo", "ubuntu-keyring", "wget", "whiptail", "wireguard",
]
APT_REMOVE_PACKAGES = ["apache2", "needrestart", "needrestart-session"]
EXCLUDED_IFACES = {"warp", "lo"}


def _ensure_bashrc_lines(rc_path, lines, stale_patterns=()):
    """
    Strip any line containing one of stale_patterns, then append the
    given lines if they're not already present. Equivalent to the legacy
    `sed -i s|X||g; echo Y >> .bashrc` pattern.
    """
    if not os.path.exists(rc_path):
        existing = []
    else:
        with open(rc_path) as f:
            existing = f.readlines()

    def is_stale(ln):
        return any(p in ln for p in stale_patterns)

    out = [ln for ln in existing if not is_stale(ln)]
    for line in lines:
        wanted = line.rstrip("\n") + "\n"
        if wanted not in out:
            if out and not out[-1].endswith("\n"):
                out[-1] = out[-1] + "\n"
            out.append(wanted)
    with open(rc_path, "w") as f:
        f.writelines(out)


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
            f"@daily root {VENV_DIR}/bin/python3 -m "
            "hiddify_manager.modules.daily_actions "
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

    # /usr/bin/hiddify wrapper. Legacy symlinked /opt/hiddify-manager/menu.sh
    # but that script was deleted in 20d2d792. Write a tiny shim that hands
    # off to ./init.sh menu (the python menu).
    hiddify_bin = "/usr/bin/hiddify"
    with open(hiddify_bin, "w") as f:
        f.write(
            "#!/bin/bash\n"
            f"exec {PROJECT_ROOT}/init.sh menu \"$@\"\n"
        )
    os.chmod(hiddify_bin, 0o755)

    # Auto-cd into the project on login + show menu. Legacy appended
    # /opt/hiddify-manager/menu.sh directly; use the new wrapper instead.
    _ensure_bashrc_lines(
        "/root/.bashrc",
        [f"cd {PROJECT_ROOT}", "hiddify"],
        stale_patterns=[
            "/opt/hiddify-manager/menu.sh",
            "cd /opt/hiddify-manager/",
        ],
    )

    for unit in ("rpcbind.socket", "rpcbind"):
        run_cmd(["systemctl", "disable", "--now", unit], check=False)


# ---------------------------------------------------------------------------
# Post-panel runtime config — replaces common/run.sh.j2.
# ---------------------------------------------------------------------------

# Country -> tz, matches the legacy if/elif/else chain.
_TIMEZONE_BY_COUNTRY = {"cn": "Asia/Shanghai", "ru": "Europe/Moscow"}
_DEFAULT_TIMEZONE = "Asia/Tehran"

# Ports we always open. Mirrors the hard-coded allow_port block at the
# top of common/run.sh.j2.
_FIXED_PORTS = [("tcp", 22), ("tcp", 80), ("tcp", 443), ("udp", 443),
                ("udp", 53), ("tcp", 53)]


def _hconfigs(configs):
    return (configs or {}).get("hconfigs") or {}


def _split_csv_ports(raw):
    """Parse a comma-separated port list from hconfigs, ignoring blanks."""
    if not raw:
        return []
    out = []
    for chunk in str(raw).split(","):
        chunk = chunk.strip()
        if not chunk:
            continue
        try:
            out.append(int(chunk))
        except ValueError:
            log.warning(f"common: skipping unparseable port {chunk!r}")
    return out


def _apply_timezone(configs):
    """Set system timezone based on hconfigs['country']."""
    if os.environ.get("MODE") == "docker":
        return
    hconfigs = _hconfigs(configs)
    country = (hconfigs.get("country") or "").lower()
    target = _TIMEZONE_BY_COUNTRY.get(country, _DEFAULT_TIMEZONE)
    res = run_cmd(["timedatectl", "show", "--property=Timezone", "--value"],
                  check=False, capture_output=True)
    current = (res.stdout or "").strip()
    if current == target:
        return
    log.info(f"common: changing timezone {current!r} -> {target!r}")
    run_cmd(["timedatectl", "set-timezone", target], check=False)
    run_cmd(["systemctl", "restart", "mariadb"], check=False)


def _apply_ports(configs):
    """Open every port the panel config says we should be listening on."""
    hconfigs = _hconfigs(configs)
    domains = (configs or {}).get("domains") or []

    for proto, port in _FIXED_PORTS:
        firewall.allow_port(proto, port)

    if hconfigs.get("wireguard_port"):
        firewall.allow_port("udp", hconfigs["wireguard_port"])

    if hconfigs.get("shadowsocks2022_enable") and hconfigs.get("shadowsocks2022_port"):
        port = hconfigs["shadowsocks2022_port"]
        firewall.allow_port("tcp", port)
        firewall.allow_port("udp", port)

    for d in domains:
        for key in ("internal_port_hysteria2", "internal_port_tuic", "internal_port_naive"):
            port = (d or {}).get(key)
            if port and int(port) > 0:
                firewall.allow_port("udp", int(port))

    if hconfigs.get("mieru_enable"):
        for port in _split_csv_ports(hconfigs.get("mieru_tcp_ports")):
            firewall.allow_port("tcp", port)
        for port in _split_csv_ports(hconfigs.get("mieru_udp_ports")):
            firewall.allow_port("udp", port)

    # Per-protocol panel ports (TLS + HTTP). Legacy opened both TCP for
    # every port in tls+http and additionally UDP for TLS-only.
    tls_ports = _split_csv_ports(hconfigs.get("tls_ports"))
    http_ports = _split_csv_ports(hconfigs.get("http_ports"))
    for port in tls_ports + http_ports:
        firewall.allow_port("tcp", port)
    for port in tls_ports:
        firewall.allow_port("udp", port)

    # SSH server (proxy, not the OS sshd).
    ssh_port = hconfigs.get("ssh_server_port")
    if ssh_port:
        if hconfigs.get("ssh_server_enable"):
            firewall.allow_port("tcp", ssh_port)
        else:
            firewall.remove_port("tcp", ssh_port)


def _apply_static_rules():
    """The fixed INPUT/OUTPUT/ICMP rules from the bottom of run.sh.j2."""
    firewall.add_rule([
        "INPUT", "-p", "udp",
        "-m", "conntrack", "--ctstatus", "SEEN_REPLY,ASSURED,CONFIRMED",
        "-j", "ACCEPT",
    ])
    firewall.add_rule(["OUTPUT", "-p", "udp", "-j", "ACCEPT"])
    firewall.add_rule(["OUTPUT", "-p", "tcp", "-j", "ACCEPT"])
    firewall.add_rule(["INPUT", "-i", "lo", "-j", "ACCEPT"])
    # ICMP allow (v4 + v6 forms differ)
    firewall.add_rule(["INPUT", "-p", "icmp", "-j", "ACCEPT"], both=False)
    firewall.add_rule_v6_only(["INPUT", "-p", "ipv6-icmp", "-j", "ACCEPT"])
    firewall.add_rule(["INPUT", "-m", "state", "--state", "ESTABLISHED,RELATED", "-j", "ACCEPT"])
    firewall.add_rule(["INPUT", "-m", "conntrack", "--ctstate", "RELATED,ESTABLISHED", "-j", "ACCEPT"])


_MOTD_WARNING = (
    "Hiddify! Your server is vulnerable to abuses because "
    "PasswordAuthentication is enabled. To secure your server, please "
    "switch to key authentication mechanism and turn off "
    "PasswordAuthentication in your ssh config file."
)


def _audit_sshd_password_auth():
    """Mirror the legacy MOTD audit: write a warning if sshd allows passwords."""
    # Find any sshd config line with PasswordAuthentication no.
    pw_disabled = False
    for path in ("/etc/ssh/sshd_config", *_glob_sshd_includes()):
        try:
            with open(path) as f:
                for line in f:
                    line = line.strip()
                    if re.fullmatch(r"PasswordAuthentication\s+no", line):
                        pw_disabled = True
                        break
        except OSError:
            continue
        if pw_disabled:
            break

    motd_path = "/etc/motd"
    try:
        with open(motd_path) as f:
            motd = f.read()
    except OSError:
        motd = ""

    if not pw_disabled:
        if "Your server is vulnerable" not in motd:
            try:
                with open(motd_path, "a") as f:
                    f.write(_MOTD_WARNING + "\n")
            except OSError as e:
                log.warning(f"common: could not append MOTD warning: {e}")
    else:
        if "Your server is vulnerable" in motd:
            new_motd = "\n".join(
                ln for ln in motd.splitlines()
                if "Your server is vulnerable" not in ln
            )
            try:
                with open(motd_path, "w") as f:
                    f.write(new_motd + ("\n" if new_motd else ""))
            except OSError as e:
                log.warning(f"common: could not rewrite MOTD: {e}")

    run_cmd(["systemctl", "restart", "sshd.service"], check=False)
    run_cmd(["systemctl", "restart", "ssh.service"], check=False)


def _glob_sshd_includes():
    """Mirror the legacy `grep -rxq ... /etc/ssh/sshd*` semantics."""
    import glob
    return sorted(glob.glob("/etc/ssh/sshd*"))


def _apply_auto_update_cron(configs):
    cron = "/etc/cron.d/hiddify_auto_update"
    if _hconfigs(configs).get("auto_update"):
        # Legacy ran `$(pwd)/../update.sh`; relative to common/, that's the
        # repo root. With the python orchestrator, init.sh update is the
        # entrypoint.
        with open(cron, "w") as f:
            f.write(
                f"0 3 * * * root {PROJECT_ROOT}/init.sh update "
                f">> {LOG_DIR}/auto_update.log 2>&1\n"
            )
    else:
        try:
            os.remove(cron)
        except FileNotFoundError:
            pass
    run_cmd(["service", "cron", "reload"], check=False)


def apply_runtime_config(configs):
    """
    Post-panel system config. Called from manager._render_all_templates
    once current.json has been generated and templates have been rendered.

    Steps mirror common/run.sh.j2 top-to-bottom: timezone, the full
    iptables/ip6tables ruleset, SSH MOTD audit, INPUT/FORWARD policy
    from hconfigs['firewall'], save the ruleset, manage auto-update cron.
    """
    if not configs:
        log.warning("common: no panel configs available — skipping runtime config")
        return

    _apply_timezone(configs)
    _apply_ports(configs)
    _apply_static_rules()
    _audit_sshd_password_auth()

    # The firewall policy flag controls whether unknown traffic is dropped.
    # Apply *after* opening the per-service ports above, otherwise DROP
    # would close the door before we held it open.
    policy = "DROP" if _hconfigs(configs).get("firewall") else "ACCEPT"
    firewall.set_input_policy(policy)

    firewall.save()
    _apply_auto_update_cron(configs)
