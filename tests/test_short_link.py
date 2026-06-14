"""Tests for modules.short_link."""
import os
from unittest.mock import patch

from hiddify_manager.modules import short_link as sl


def test_add_appends_location_block(tmp_path):
    conf = tmp_path / "short-link.conf"
    with patch.object(sl, "SHORT_LINK_CONF", str(conf)), \
         patch.object(sl, "run_cmd"):
        rc = sl.add("https://example.com/path", "abc123", 5)
    assert rc == 0
    body = conf.read_text()
    assert "location ~* ^/abc123(/)?$" in body
    assert "return 302 https://example.com/path" in body


def test_add_appends_not_overwrites(tmp_path):
    conf = tmp_path / "short-link.conf"
    conf.write_text("# existing entry\n")
    with patch.object(sl, "SHORT_LINK_CONF", str(conf)), \
         patch.object(sl, "run_cmd"):
        sl.add("https://x.test", "y", 1)
    body = conf.read_text()
    assert "# existing entry" in body
    assert "/y(/)?" in body


def test_add_schedules_at_job(tmp_path):
    conf = tmp_path / "short-link.conf"
    with patch.object(sl, "SHORT_LINK_CONF", str(conf)), \
         patch.object(sl, "run_cmd") as m:
        sl.add("https://example.com", "slug", 15)
    at_calls = [c for c in m.call_args_list if c.args[0][0] == "at"]
    assert len(at_calls) == 1
    argv = at_calls[0].args[0]
    assert argv == ["at", "now", "+15", "minutes"]
    # The sed command piped to at strips the slug's line.
    stdin = at_calls[0].kwargs.get("input_data", "")
    assert "/slug(" in stdin
    assert "sed -i" in stdin


def test_add_reloads_nginx(tmp_path):
    conf = tmp_path / "short-link.conf"
    with patch.object(sl, "SHORT_LINK_CONF", str(conf)), \
         patch.object(sl, "run_cmd") as m:
        sl.add("https://x.test", "y", 1)
    reload_calls = [
        c for c in m.call_args_list
        if c.args[0][:2] == ["systemctl", "reload"]
    ]
    assert len(reload_calls) == 1


def test_add_rejects_bad_slug(tmp_path):
    conf = tmp_path / "short-link.conf"
    with patch.object(sl, "SHORT_LINK_CONF", str(conf)), \
         patch.object(sl, "run_cmd") as m:
        rc = sl.add("https://x.test", "../etc/passwd", 1)
    assert rc != 0
    assert not conf.exists() or "passwd" not in conf.read_text()
    # No at scheduling, no reload.
    assert not any(c.args[0][0] == "at" for c in m.call_args_list)


def test_add_rejects_bad_minutes(tmp_path):
    conf = tmp_path / "short-link.conf"
    with patch.object(sl, "SHORT_LINK_CONF", str(conf)), \
         patch.object(sl, "run_cmd"):
        assert sl.add("https://x.test", "y", "abc") != 0
        assert sl.add("https://x.test", "y", 0) != 0
        assert sl.add("https://x.test", "y", -5) != 0
