from __future__ import annotations

from types import SimpleNamespace

from hiddifypanel.proxy_v3.builtin_proxy_sync.stale import (
    demote_builtin_base_config,
    demote_builtin_template,
    prepare_repromotion_template,
)
from hiddifypanel.proxy_v3.builtin_proxy_sync.sync import has_custom_proxy_overrides


def test_prepare_repromotion_template_sets_override_when_content_differs() -> None:
    row = SimpleNamespace(
        is_builtin=False,
        content='user edit',
        builtin_override=False,
        builtin_content='catalog',
    )
    prepare_repromotion_template(row, 'catalog')
    assert row.is_builtin is True
    assert row.builtin_override is True


def test_prepare_repromotion_template_no_override_when_content_matches() -> None:
    row = SimpleNamespace(
        is_builtin=False,
        content='catalog',
        builtin_override=False,
        builtin_content='',
    )
    prepare_repromotion_template(row, 'catalog')
    assert row.is_builtin is True
    assert row.builtin_override is False


def test_demote_builtin_template_preserves_content() -> None:
    row = SimpleNamespace(
        is_builtin=True,
        content='user edit',
        builtin_override=True,
        builtin_content='catalog',
    )
    demote_builtin_template(row)
    assert row.is_builtin is False
    assert row.builtin_override is False
    assert row.builtin_content == ''
    assert row.content == 'user edit'


def test_demote_builtin_base_config_preserves_content() -> None:
    row = SimpleNamespace(
        is_builtin=True,
        content='user edit',
        builtin_override=True,
        builtin_content='catalog',
    )
    demote_builtin_base_config(row)
    assert row.is_builtin is False
    assert row.content == 'user edit'


def test_has_custom_proxy_overrides_detects_server_override() -> None:
    row = SimpleNamespace(
        builtin=None,
        builtin_overrides={'server_config': True},
        server_override=True,
        client_cores=[],
    )
    assert has_custom_proxy_overrides(row) is True


def test_has_custom_proxy_overrides_false_when_clean() -> None:
    row = SimpleNamespace(
        builtin={},
        builtin_overrides={},
        server_override=False,
        client_cores=[],
    )
    assert has_custom_proxy_overrides(row) is False
