"""
WireGuard server for end-user clients (hiddifywg interface).

Replaces other/wireguard/{install.sh.j2,run.sh.j2}: writes
/etc/wireguard/hiddifywg.conf with the panel-derived [Interface]
block + iptables/ip6tables PostUp/PostDown rules, then renders one
[Peer] per panel user (address per-peer derived by adding the user
id to the configured wg base address). Enables IP forwarding via
sysctl. Restarts wg-quick@hiddifywg.

Unlike the legacy split (install once + run-on-config-change), we
rebuild the full config on every orchestrator run — simpler, and the
wg-quick restart is fast enough for the install path.
"""
import ipaddress
import os
import re

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.config import hiddify_config


SERVER_WG_NIC = "hiddifywg"
SERVER_CONF = f"/etc/wireguard/{SERVER_WG_NIC}.conf"
PARAMS_FILE = "/etc/wireguard/params"
SYSCTL_FILE = "/etc/sysctl.d/wg.conf"
REQUIRED_HCONFIGS = [
    "wireguard_ipv4", "wireguard_ipv6",
    "wireguard_port", "wireguard_private_key",
]


def _default_iface():
    """Public-facing NIC name. Equivalent to `ip -4 route show default | awk '/dev/{...}'`."""
    res = run_cmd(["ip", "-4", "route", "show", "default"], check=False, capture_output=True)
    if res.returncode != 0 or not res.stdout:
        return None
    line = res.stdout.splitlines()[0] if res.stdout.splitlines() else ""
    m = re.search(r"\bdev\s+(\S+)", line)
    return m.group(1) if m else None


def _add_int_to_ip(ip_str, n):
    """
    Add n to an IPv4 or IPv6 address. Proper carries, unlike the legacy
    bash helpers which only carried v4 once (octets[2..3]) and never
    carried v6 at all.
    """
    return str(ipaddress.ip_address(ip_str) + n)


def _interface_block(hconfigs, pub_nic):
    port = hconfigs["wireguard_port"]
    ipv4 = hconfigs["wireguard_ipv4"]
    ipv6 = hconfigs["wireguard_ipv6"]
    priv = hconfigs["wireguard_private_key"]
    return (
        "[Interface]\n"
        f"Address = {ipv4}/16,{ipv6}/90\n"
        f"ListenPort = {port}\n"
        f"PrivateKey = {priv}\n"
        "\n"
        f"PostUp = iptables -I INPUT -p udp --dport {port} -j ACCEPT\n"
        f"PostUp = iptables -I FORWARD -i {pub_nic} -o {SERVER_WG_NIC} -j ACCEPT\n"
        f"PostUp = iptables -I FORWARD -i {SERVER_WG_NIC} -j ACCEPT\n"
        f"PostUp = iptables -t nat -A POSTROUTING -o {pub_nic} -j MASQUERADE\n"
        f"PostUp = ip6tables -I FORWARD -i {SERVER_WG_NIC} -j ACCEPT\n"
        f"PostUp = ip6tables -t nat -A POSTROUTING -o {pub_nic} -j MASQUERADE\n"
        f"PostDown = iptables -D INPUT -p udp --dport {port} -j ACCEPT\n"
        f"PostDown = iptables -D FORWARD -i {pub_nic} -o {SERVER_WG_NIC} -j ACCEPT\n"
        f"PostDown = iptables -D FORWARD -i {SERVER_WG_NIC} -j ACCEPT\n"
        f"PostDown = iptables -t nat -D POSTROUTING -o {pub_nic} -j MASQUERADE\n"
        f"PostDown = ip6tables -D FORWARD -i {SERVER_WG_NIC} -j ACCEPT\n"
        f"PostDown = ip6tables -t nat -D POSTROUTING -o {pub_nic} -j MASQUERADE\n"
    )


def _peer_blocks(users, hconfigs):
    base_v4 = hconfigs["wireguard_ipv4"]
    base_v6 = hconfigs["wireguard_ipv6"]
    out = []
    for u in users or []:
        uid = u.get("id")
        pub = u.get("wg_pub")
        psk = u.get("wg_psk")
        if uid is None or not pub:
            continue
        try:
            v4 = _add_int_to_ip(base_v4, uid)
            v6 = _add_int_to_ip(base_v6, uid)
        except ValueError as e:
            log.warning(f"wireguard: bad address math for user {uid}: {e}")
            continue
        block = "\n[Peer]\n"
        block += f"PublicKey = {pub}\n"
        if psk:
            block += f"PresharedKey = {psk}\n"
        block += f"AllowedIPs = {v4}/32,{v6}/128\n"
        out.append(block)
    return "".join(out)


def _params_content(hconfigs, pub_nic):
    """The same env-style file the legacy install.sh wrote to /etc/wireguard/params."""
    port = hconfigs["wireguard_port"]
    ipv4 = hconfigs["wireguard_ipv4"]
    ipv6 = hconfigs["wireguard_ipv6"]
    priv = hconfigs["wireguard_private_key"]
    pub_key = hconfigs.get("wireguard_public_key", "")
    dns = hconfigs.get("dns_server", "1.1.1.1")
    return (
        f"SERVER_PUB_NIC={pub_nic}\n\n"
        f"SERVER_WG_IPV4={ipv4}\n"
        f"SERVER_WG_IPV6={ipv6}\n"
        f"SERVER_PORT={port}\n"
        f"SERVER_PRIV_KEY={priv}\n"
        f"#SERVER_PUB_KEY={pub_key}\n"
        f"CLIENT_DNS_1={dns}\n"
        f"CLIENT_DNS_2=1.1.1.1\n"
        f"ALLOWED_IPS=0.0.0.0,::/0\n"
    )


def _write(path, content, mode):
    """Atomic file write with the requested mode."""
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write(content)
    os.chmod(tmp, mode)
    os.replace(tmp, path)


def install():
    configs = hiddify_config()
    if not configs:
        log.error("wireguard: no panel configs available — aborting")
        return
    hconfigs = configs.get("hconfigs") or {}

    missing = [k for k in REQUIRED_HCONFIGS if not hconfigs.get(k)]
    if missing:
        log.warning(f"wireguard: missing required hconfigs {missing} — skipping")
        return

    run_cmd(["apt-get", "install", "-y", "wireguard"], check=False)
    os.makedirs("/etc/wireguard", exist_ok=True)

    pub_nic = _default_iface()
    if not pub_nic:
        log.error("wireguard: could not detect public default interface")
        return

    # Bring the interface down before rewriting its config so wg-quick's
    # PostDown rules run with the values it brought up with.
    run_cmd(["systemctl", "stop", f"wg-quick@{SERVER_WG_NIC}"], check=False)

    _write(PARAMS_FILE, _params_content(hconfigs, pub_nic), 0o660)

    body = _interface_block(hconfigs, pub_nic) + _peer_blocks(configs.get("users"), hconfigs)
    _write(SERVER_CONF, body, 0o660)

    _write(SYSCTL_FILE,
           "net.ipv4.ip_forward = 1\nnet.ipv6.conf.all.forwarding = 1\n",
           0o644)
    if os.environ.get("MODE") != "docker":
        run_cmd(["sysctl", "--system"], check=False, capture_output=True)

    run_cmd(["systemctl", "enable", f"wg-quick@{SERVER_WG_NIC}"], check=False)
    run_cmd(["systemctl", "restart", f"wg-quick@{SERVER_WG_NIC}"], check=False)
