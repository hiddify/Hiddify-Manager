from __future__ import annotations

import pytest

from hiddifypanel.proxy_v3.builtin_proxy_sync.discovery import (
    classify_path,
    is_base_config_path,
    is_preset_path,
    parse_base_config_path,
)


@pytest.mark.parametrize(
    ('rel', 'expected'),
    [
        ('xray/client/base.j2', 'base'),
        ('xray/server/base.j2', 'base'),
        ('hiddify-core/client/base.j2', 'base'),
        ('hiddify-core/server/base.j2', 'base'),
        ('haproxy/server/base.j2', 'base'),
        ('rust-rpxy-l4/server/base.j2', 'base'),
        ('sublink/client/base.j2', 'base'),
        ('xray/server/presets/inbound.pj2', 'preset'),
        ('hiddify-core/client/presets/outbound_v2ray.pj2', 'preset'),
        ('hiddify-core/server/base/dns.pj2', 'template'),
        ('hiddify-core/server/base/route.pj2', 'template'),
        ('xray/common/protocols/vless.pj2', 'template'),
        ('singbox/client/base.pj2', 'template'),
    ],
)
def test_classify_path(rel: str, expected: str) -> None:
    assert classify_path(rel) == expected


def test_is_base_config_path() -> None:
    assert is_base_config_path('xray/client/base.j2')
    assert is_base_config_path('hiddify-core/client/base.j2')
    assert not is_base_config_path('hiddify-core/server/base/dns.pj2')


def test_parse_base_config_path() -> None:
    assert parse_base_config_path('xray/server/base.j2') == ('xray', 'server')
    assert parse_base_config_path('haproxy/server/base.j2') == ('haproxy', 'server')
    assert parse_base_config_path('hiddify-core/server/base/dns.pj2') is None


def test_is_preset_path() -> None:
    assert is_preset_path('xray/server/presets/inbound.pj2')
    assert not is_preset_path('xray/common/protocols/vless.pj2')
