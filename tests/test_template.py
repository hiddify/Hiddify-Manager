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


def test_render_json_strips_trailing_commas(tmp_path):
    """
    Regression test for the singbox crashloop: jinja-rendered .json files
    can have trailing commas (legal in json5, used by the upstream
    templates) but the hiddify-core consumer parses strict JSON. When
    the output path ends in .json, we re-parse via json5 and re-emit
    canonical JSON.
    """
    tpl = tmp_path / "x.json.j2"
    tpl.write_text('{\n  "users": [\n    {"name": "a"},\n  ],\n}\n')
    out_path = render_template(str(tpl), CONFIGS)
    assert out_path == str(tmp_path / "x.json")
    import json
    # Strict json.loads should succeed on the rendered output.
    data = json.loads((tmp_path / "x.json").read_text())
    assert data == {"users": [{"name": "a"}]}


def test_render_non_json_output_unchanged(tmp_path):
    """The json5 reparse should NOT touch non-.json output."""
    tpl = tmp_path / "x.cfg.j2"
    tpl.write_text("[block]\nkey = value,\n")
    render_template(str(tpl), CONFIGS)
    # Jinja's render strips a single trailing newline; assert structure
    # rather than byte-for-byte equality.
    out = (tmp_path / "x.cfg").read_text()
    assert "key = value," in out
    assert "[block]" in out


def test_render_json_with_invalid_json5_falls_through(tmp_path):
    """
    If the rendered output isn't even valid json5, write it anyway so the
    operator can see the broken file (legacy common/jinja.py did the same).
    """
    tpl = tmp_path / "x.json.j2"
    tpl.write_text("this is not json at all")
    out_path = render_template(str(tpl), CONFIGS)
    assert out_path is not None
    assert "not json" in (tmp_path / "x.json").read_text()


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
