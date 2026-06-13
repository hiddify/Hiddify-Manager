import json
import os
import tempfile

import pytest

from hiddify_manager.utils.template import render_template, _prepare_configs


CONFIGS = {
    "chconfigs": {"0": {"warp_plus_code": "ABC123", "wireguard_port": 51820}},
    "domains": [{"domain": "example.com"}],
}


def test_prepare_configs_surfaces_hconfigs():
    out = _prepare_configs(CONFIGS)
    assert out["hconfigs"]["warp_plus_code"] == "ABC123"
    assert out["chconfigs"][0]["wireguard_port"] == 51820


def test_render_template_basic(tmp_path):
    tpl = tmp_path / "x.conf.j2"
    tpl.write_text(
        "KEY={{ hconfigs['warp_plus_code'] }}\n"
        "PORT={{ hconfigs['wireguard_port'] }}\n"
    )
    out = render_template(str(tpl), CONFIGS)
    assert out == str(tmp_path / "x.conf")
    rendered = (tmp_path / "x.conf").read_text()
    assert "KEY=ABC123" in rendered
    assert "PORT=51820" in rendered


def test_render_template_filters(tmp_path):
    tpl = tmp_path / "f.j2"
    tpl.write_text("B={{ 'hi' | b64encode }}\nQ={{ 'a b' | quote }}\n")
    render_template(str(tpl), CONFIGS)
    rendered = (tmp_path / "f").read_text()
    assert "B=aGk=" in rendered
    assert "Q=a%20b" in rendered


def test_render_template_preserves_mode(tmp_path):
    tpl = tmp_path / "m.j2"
    tpl.write_text("hello")
    os.chmod(str(tpl), 0o640)
    render_template(str(tpl), CONFIGS)
    assert oct(os.stat(tmp_path / "m").st_mode)[-3:] == "640"


def test_render_template_missing_key_returns_none(tmp_path):
    tpl = tmp_path / "bad.j2"
    tpl.write_text("{{ hconfigs['missing']['x'] }}")
    assert render_template(str(tpl), CONFIGS) is None
    assert not (tmp_path / "bad").exists()


def test_prepare_configs_empty():
    assert _prepare_configs(None) == {}
    assert _prepare_configs({}) == {}


def test_render_template_relative_include(tmp_path):
    """`{% include "sibling.j2" %}` should resolve against the template's dir."""
    inc_dir = tmp_path / "parts"
    inc_dir.mkdir()
    (inc_dir / "snippet.j2").write_text("hello {{ hconfigs['warp_plus_code'] }}")
    tpl = tmp_path / "main.j2"
    tpl.write_text('{% include "parts/snippet.j2" %}!\n')

    out = render_template(str(tpl), CONFIGS)
    assert out == str(tmp_path / "main")
    assert (tmp_path / "main").read_text().strip() == "hello ABC123!"
