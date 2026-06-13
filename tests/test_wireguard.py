"""Tests for the pure helpers in hiddify_manager.modules.wireguard."""
from unittest.mock import patch

from hiddify_manager.modules import wireguard


HCONFIGS = {
    "wireguard_ipv4": "10.90.0.1",
    "wireguard_ipv6": "fd42:42::1",
    "wireguard_port": 51820,
    "wireguard_private_key": "PRIVKEY",
    "wireguard_public_key": "PUBKEY",
    "dns_server": "8.8.8.8",
}


def test_add_int_to_ip_v4_carries_octets():
    assert wireguard._add_int_to_ip("10.0.0.250", 5) == "10.0.0.255"
    # legacy bash carried 3->2 only; python carries all the way
    assert wireguard._add_int_to_ip("10.0.0.250", 10) == "10.0.1.4"
    assert wireguard._add_int_to_ip("10.0.255.250", 10) == "10.1.0.4"


def test_add_int_to_ip_v6_carries_segments():
    # legacy v6 bash never carried; python does
    assert wireguard._add_int_to_ip("fd42:42::ffff", 1) == "fd42:42::1:0"
    assert wireguard._add_int_to_ip("fd42:42::1", 5) == "fd42:42::6"


def test_add_int_to_ip_invalid_raises():
    import pytest
    with pytest.raises(ValueError):
        wireguard._add_int_to_ip("not-an-ip", 1)


def test_interface_block_contains_panel_values():
    block = wireguard._interface_block(HCONFIGS, "eth0")
    assert "Address = 10.90.0.1/16,fd42:42::1/90" in block
    assert "ListenPort = 51820" in block
    assert "PrivateKey = PRIVKEY" in block
    # iptables rules reference both interfaces
    assert "iptables -I FORWARD -i eth0 -o hiddifywg" in block
    assert "ip6tables -t nat -A POSTROUTING -o eth0" in block
    # And the matching PostDown removes them
    assert "iptables -D INPUT -p udp --dport 51820" in block


def test_peer_blocks_one_per_user_with_carried_addresses():
    users = [
        {"id": 1, "wg_pub": "PUB_A", "wg_psk": "PSK_A"},
        {"id": 2, "wg_pub": "PUB_B", "wg_psk": ""},  # PSK omitted
        {"id": 257, "wg_pub": "PUB_C", "wg_psk": "PSK_C"},  # carries v4
    ]
    out = wireguard._peer_blocks(users, HCONFIGS)
    # User 1
    assert "PublicKey = PUB_A" in out
    assert "PresharedKey = PSK_A" in out
    assert "AllowedIPs = 10.90.0.2/32,fd42:42::2/128" in out
    # User 2: no PSK line
    assert "PublicKey = PUB_B" in out
    assert "PresharedKey =\n" not in out  # not emitted when empty
    # User 257: v4 last octet 1+257 = 258 -> carry into third octet
    assert "AllowedIPs = 10.90.1.2/32,fd42:42::102/128" in out


def test_peer_blocks_skips_users_without_pub():
    users = [
        {"id": 1, "wg_pub": "", "wg_psk": "PSK"},
        {"id": 2, "wg_pub": None, "wg_psk": "PSK"},
        {"id": 3, "wg_pub": "OK", "wg_psk": "PSK"},
    ]
    out = wireguard._peer_blocks(users, HCONFIGS)
    assert out.count("[Peer]") == 1
    assert "PublicKey = OK" in out


def test_peer_blocks_empty_users():
    assert wireguard._peer_blocks(None, HCONFIGS) == ""
    assert wireguard._peer_blocks([], HCONFIGS) == ""


def test_params_content_contains_panel_values():
    out = wireguard._params_content(HCONFIGS, "eth0")
    assert "SERVER_PUB_NIC=eth0" in out
    assert "SERVER_WG_IPV4=10.90.0.1" in out
    assert "SERVER_PORT=51820" in out
    assert "SERVER_PRIV_KEY=PRIVKEY" in out
    assert "CLIENT_DNS_1=8.8.8.8" in out


def test_default_iface_parses_ip_route_output():
    fake = type("R", (), {"returncode": 0,
                          "stdout": "default via 192.168.1.1 dev eth0 proto static metric 100\n"})
    with patch.object(wireguard, "run_cmd", return_value=fake):
        assert wireguard._default_iface() == "eth0"


def test_default_iface_returns_none_when_no_default_route():
    fake = type("R", (), {"returncode": 0, "stdout": ""})
    with patch.object(wireguard, "run_cmd", return_value=fake):
        assert wireguard._default_iface() is None
