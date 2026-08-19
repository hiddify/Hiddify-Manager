from __future__ import annotations

from hiddifypanel.proxy_v3.builtin_proxy_sync.catalog import (
    clear_builtin_template_cache,
    discover_base_configs,
    discover_builtin_templates,
)
from hiddifypanel.proxy_v3.builtin_proxy_sync.discovery import iter_base_config_files


def test_iter_base_config_files_finds_canonical_layout() -> None:
    found = {(core, side) for core, side, _path in iter_base_config_files()}
    assert ('xray', 'client') in found
    assert ('xray', 'server') in found
    assert ('hiddify-core', 'client') in found
    assert ('hiddify-core', 'server') in found
    assert ('haproxy', 'server') in found
    assert ('rust-rpxy-l4', 'server') in found
    assert ('sublink', 'client') in found


def test_discover_builtin_templates_excludes_base_shells() -> None:
    clear_builtin_template_cache()
    slugs = {tpl.slug for tpl in discover_builtin_templates()}
    assert 'xray/client/base' not in slugs
    assert 'xray/server/base' not in slugs
    assert 'hiddify-core/server/base/dns' in slugs


def test_discover_base_configs_loads_hiddify_core_server_shell() -> None:
    clear_builtin_template_cache()
    configs = discover_base_configs()
    by_key = {(cfg.core, cfg.side): cfg.content for cfg in configs}
    assert "hiddify-core/server/base/route" in by_key[('hiddify-core', 'server')]
