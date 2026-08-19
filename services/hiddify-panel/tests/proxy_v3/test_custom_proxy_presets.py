from __future__ import annotations

from hiddifypanel.models.custom_proxy import CustomProxyMode, InboundTcpUdp
from hiddifypanel.proxy_v3.template_catalog.custom_proxy_builtin import (
    DERIVED_BUILTIN_FIELDS,
    SERVER_OVERRIDE_FIELDS,
)
from hiddifypanel.proxy_v3.template_catalog.custom_proxy_presets import (
    BOTH_PROTOS,
    build_reality_termination_preset,
    iter_custom_proxy_presets,
)


def test_tcp_udp_is_not_builtin_override_field() -> None:
    assert "server_inbound_tcp_udp" not in SERVER_OVERRIDE_FIELDS
    assert "server_inbound_download_tcp_udp" not in SERVER_OVERRIDE_FIELDS
    assert "server_inbound_tcp_udp" in DERIVED_BUILTIN_FIELDS
    assert "server_inbound_download_tcp_udp" in DERIVED_BUILTIN_FIELDS
    assert "server_inbound_upload_tcp_udp" not in DERIVED_BUILTIN_FIELDS


def _presets_by_proto(proto: str):
    return [p for p in iter_custom_proxy_presets() if p.proto == proto]


def _presets_by_transport(transport: str):
    return [p for p in iter_custom_proxy_presets() if p.transport == transport]


def test_tuic_hysteria_anytls_use_sni_gateway() -> None:
    for proto in ("tuic", "hysteria", "hysteria2", "anytls"):
        presets = _presets_by_proto(proto)
        assert presets, f"expected builtin presets for {proto}"
        for preset in presets:
            assert preset.mode == CustomProxyMode.domains_sni_gateway
            assert preset.domain_modes == ("direct", "relay")
            assert "fake" not in preset.domain_modes


def _presets_with_category(category: str):
    return [p for p in iter_custom_proxy_presets() if category in p.categories]


def test_naive_uses_direct_relay_and_shadowtls_is_fake_only() -> None:
    for preset in _presets_by_proto("naive"):
        assert preset.domain_modes == ("direct", "relay")
        assert "fake" not in preset.domain_modes
    shadowtls_presets = _presets_with_category("shadowtls")
    assert shadowtls_presets, "expected builtin ShadowTLS presets"
    for preset in shadowtls_presets:
        assert preset.domain_modes == ("fake",)
        assert preset.mode == CustomProxyMode.domains_sni_gateway


def test_faketls_is_sni_gateway_fake_only() -> None:
    faketls_presets = _presets_with_category("faketls")
    assert faketls_presets, "expected builtin FakeTLS presets"
    for preset in faketls_presets:
        assert preset.mode == CustomProxyMode.domains_sni_gateway
        assert preset.domain_modes == ("fake",)


def test_ssh_builtin_preset_exists() -> None:
    presets = _presets_by_proto("ssh")
    assert presets, "expected builtin SSH presets"
    for preset in presets:
        assert preset.mode == CustomProxyMode.domains_auto_public_ports
        assert preset.domain_modes == ("direct", "relay")
        assert preset.transport == "other"


def test_ip_based_protos_use_direct_relay() -> None:
    for proto in ("ssh", "wireguard", "mieru", "snell"):
        presets = _presets_by_proto(proto)
        assert presets, f"expected builtin presets for {proto}"
        for preset in presets:
            assert preset.domain_modes == ("direct", "relay")


def test_reality_termination_uses_reality_domain_mode() -> None:
    preset = build_reality_termination_preset()
    assert preset.domain_modes == ("reality",)


def test_tuic_and_hysteria_are_udp_only() -> None:
    for proto in ("tuic", "hysteria", "hysteria2"):
        for preset in _presets_by_proto(proto):
            assert preset.tcp_udp == InboundTcpUdp.udp


def test_reality_presets_are_tcp_only() -> None:
    reality_presets = [
        p
        for p in iter_custom_proxy_presets()
        if "reality" in p.categories
    ]
    assert reality_presets
    for preset in reality_presets:
        assert preset.tcp_udp == InboundTcpUdp.tcp


def test_reality_termination_is_sni_gateway_tcp_only() -> None:
    preset = build_reality_termination_preset()
    assert preset.mode == CustomProxyMode.domains_sni_gateway
    assert preset.tcp_udp == InboundTcpUdp.tcp


def test_v2ray_transports_are_tcp_only() -> None:
    skip_protos = BOTH_PROTOS
    for transport in ("grpc", "httpupgrade", "tcp", "ws"):
        presets = [p for p in _presets_by_transport(transport) if p.proto not in skip_protos]
        assert presets, f"expected builtin presets for transport {transport}"
        for preset in presets:
            assert preset.tcp_udp == InboundTcpUdp.tcp, preset.name


def test_xhttp_upload_download_tcp_udp() -> None:
    xhttp_presets = _presets_by_transport("xhttp")
    assert xhttp_presets
    for preset in xhttp_presets:
        assert preset.tcp_udp is not None
        assert preset.download_tcp_udp is not None
        upload_quic = "up:quic" in preset.categories
        download_quic = "down:quic" in preset.categories
        if upload_quic:
            assert preset.tcp_udp == InboundTcpUdp.udp, preset.name
        else:
            assert preset.tcp_udp == InboundTcpUdp.tcp, preset.name
        if download_quic:
            assert preset.download_tcp_udp == InboundTcpUdp.udp, preset.name
        else:
            assert preset.download_tcp_udp == InboundTcpUdp.tcp, preset.name


def test_xhttp_quic_presets_exclude_reality_domain_modes() -> None:
    for preset in _presets_by_transport("xhttp"):
        if "up:quic" in preset.categories:
            assert "reality" not in preset.domain_modes, preset.name
        if "down:quic" in preset.categories:
            assert "reality" not in preset.download_domain_modes, preset.name


def test_v2ray_protos_exclude_reality_domain_mode() -> None:
    for preset in iter_custom_proxy_presets():
        if preset.proto not in ("vless", "vmess", "trojan"):
            continue
        if preset.mode != CustomProxyMode.domains_l7_gateway:
            continue
        assert "reality" not in preset.domain_modes, preset.name
        if preset.download_domain_modes:
            assert "reality" not in preset.download_domain_modes, preset.name


def test_v2ray_tcp_no_cdn_or_fake() -> None:
    for preset in _presets_by_transport("tcp"):
        if preset.proto not in ("vless", "vmess", "trojan"):
            continue
        assert "cdn" not in preset.domain_modes, preset.name
        assert "fake" not in preset.domain_modes, preset.name


def test_v2ray_cdn_capable_transports_have_cdn() -> None:
    for transport in ("ws", "grpc", "httpupgrade", "xhttp"):
        presets = [
            p
            for p in _presets_by_transport(transport)
            if p.proto in ("vless", "vmess", "trojan")
        ]
        assert presets, f"expected v2ray presets for transport {transport}"
        for preset in presets:
            assert "cdn" in preset.domain_modes, preset.name
            assert "fake" not in preset.domain_modes, preset.name


def test_proto_tcp_udp_rules() -> None:
    for preset in _presets_by_proto("wireguard"):
        assert preset.tcp_udp == InboundTcpUdp.udp
    for preset in _presets_by_proto("ssh"):
        assert preset.tcp_udp == InboundTcpUdp.tcp
    for preset in _presets_by_proto("anytls"):
        assert preset.tcp_udp == InboundTcpUdp.tcp
    for proto in ("mieru", "socks", "shadowsocks"):
        presets = _presets_by_proto(proto)
        assert presets, f"expected builtin presets for {proto}"
        for preset in presets:
            assert preset.tcp_udp == InboundTcpUdp.both, preset.name
