"""Tests for modules.update_usage."""
import json
import time
import urllib.error
from types import SimpleNamespace
from unittest.mock import patch, MagicMock

import pytest

from hiddify_manager.modules import update_usage as uu


# ---- locks ----------------------------------------------------------------

def test_set_lock_creates_file(tmp_path):
    with patch.object(uu, "LOCK_DIR", str(tmp_path)):
        uu._set_lock("x")
    assert (tmp_path / "x.lock").exists()


def test_set_lock_busy_when_recent(tmp_path):
    with patch.object(uu, "LOCK_DIR", str(tmp_path)):
        (tmp_path / "x.lock").write_text(str(int(time.time())))
        with pytest.raises(uu.LockBusy):
            uu._set_lock("x")


def test_set_lock_stamps_when_stale(tmp_path):
    """A lock older than LOCK_TTL is overwritten, not raised."""
    with patch.object(uu, "LOCK_DIR", str(tmp_path)):
        (tmp_path / "x.lock").write_text(str(int(time.time() - uu.LOCK_TTL - 10)))
        uu._set_lock("x")  # should not raise
    stamp = int((tmp_path / "x.lock").read_text())
    assert time.time() - stamp < 5


def test_remove_lock_tolerates_missing(tmp_path):
    with patch.object(uu, "LOCK_DIR", str(tmp_path)):
        uu._remove_lock("never_existed")  # should not raise


# ---- http_api -------------------------------------------------------------

def test_http_api_calls_url_with_api_key_header(tmp_path):
    cj = tmp_path / "current.json"
    cj.write_text(json.dumps({"api_path": "abc/xyz", "api_key": "K"}))
    captured = {}
    def fake_urlopen(req, timeout=None):
        captured["url"] = req.full_url
        captured["headers"] = dict(req.header_items())
        m = MagicMock()
        m.__enter__.return_value = SimpleNamespace(status=200, read=lambda: b"ok")
        m.__exit__ = MagicMock(return_value=None)
        return m
    with patch.object(uu, "CURRENT_JSON", str(cj)), \
         patch.object(uu.urllib.request, "urlopen", side_effect=fake_urlopen):
        status, body = uu._panel_http_api("admin/foo/")
    assert status == 200
    assert "abc/xyz/api/v2/admin/foo/" in captured["url"]
    # urllib lowercases header keys
    assert captured["headers"].get("Hiddify-api-key") == "K"


def test_http_api_returns_status_on_http_error(tmp_path):
    cj = tmp_path / "current.json"
    cj.write_text(json.dumps({"api_path": "p", "api_key": "K"}))
    err = urllib.error.HTTPError("u", 500, "boom", {}, None)
    err.read = lambda: b"err"
    with patch.object(uu, "CURRENT_JSON", str(cj)), \
         patch.object(uu.urllib.request, "urlopen", side_effect=err):
        status, body = uu._panel_http_api("admin/foo/")
    assert status == 500


def test_http_api_raises_when_keys_missing(tmp_path):
    cj = tmp_path / "current.json"
    cj.write_text(json.dumps({"api_path": "", "api_key": ""}))
    with patch.object(uu, "CURRENT_JSON", str(cj)):
        with pytest.raises(ValueError):
            uu._panel_http_api("admin/foo/")


# ---- run() ---------------------------------------------------------------

def test_run_returns_zero_on_200(tmp_path):
    with patch.object(uu, "_panel_http_api", return_value=(200, b"")), \
         patch.object(uu, "_is_panel_update_usage_running") as ip, \
         patch.object(uu, "_cli_fallback") as fb:
        assert uu.run() == 0
    ip.assert_not_called()
    fb.assert_not_called()


def test_run_falls_back_to_cli_when_http_fails(tmp_path):
    with patch.object(uu, "_panel_http_api", return_value=(500, b"err")), \
         patch.object(uu, "_is_panel_update_usage_running", return_value=False), \
         patch.object(uu, "_cli_fallback") as fb:
        uu.run()
    fb.assert_called_once()


def test_run_skips_cli_fallback_when_already_running(tmp_path):
    """Matches the legacy `&& [ -z $(pgrep -f 'hiddifypanel update-usage') ]`."""
    with patch.object(uu, "_panel_http_api", return_value=(500, b"err")), \
         patch.object(uu, "_is_panel_update_usage_running", return_value=True), \
         patch.object(uu, "_cli_fallback") as fb:
        uu.run()
    fb.assert_not_called()


def test_main_handles_busy_lock_silently(tmp_path):
    with patch.object(uu, "LOCK_DIR", str(tmp_path)):
        (tmp_path / "update_usage.lock").write_text(str(int(time.time())))
        with patch.object(uu, "run") as r:
            assert uu.main() == 0
        r.assert_not_called()
