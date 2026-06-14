"""Tests for modules.admin_links."""
import json
from unittest.mock import patch

from hiddify_manager.modules import admin_links as al


def test_classify_http_marks_insecure():
    tag, colour = al._classify("http://example.com/admin/abc/")
    assert tag == "[insecure]"
    assert colour == "red"


def test_classify_https_ip_marks_self_signed():
    """An https:// URL whose host is a literal IPv4 address means the
    cert is self-signed (no public CA issues for IPs)."""
    tag, colour = al._classify("https://1.2.3.4/admin/")
    assert tag == "[self-signed]"
    assert colour == "yellow"
    # With port
    tag, colour = al._classify("https://1.2.3.4:8443/admin/")
    assert tag == "[self-signed]"


def test_classify_https_domain_is_green():
    tag, colour = al._classify("https://panel.example.com/admin/secret/")
    assert tag == ""
    assert colour == "green"


def test_show_prints_each_link(tmp_path):
    cj = tmp_path / "current.json"
    cj.write_text(json.dumps({"panel_links": [
        "http://1.2.3.4/admin/a/",
        "https://panel.example.com/admin/b/",
    ]}))
    with patch.object(al, "CURRENT_JSON", str(cj)):
        rc = al.show()
    assert rc == 0


def test_show_returns_nonzero_when_no_links(tmp_path):
    cj = tmp_path / "current.json"
    cj.write_text(json.dumps({}))
    with patch.object(al, "CURRENT_JSON", str(cj)):
        assert al.show() == 1


def test_show_returns_nonzero_when_current_json_missing(tmp_path):
    cj = tmp_path / "absent"
    with patch.object(al, "CURRENT_JSON", str(cj)):
        assert al.show() == 1


def test_show_returns_nonzero_when_current_json_garbage(tmp_path):
    cj = tmp_path / "current.json"
    cj.write_text("{not json")
    with patch.object(al, "CURRENT_JSON", str(cj)):
        assert al.show() == 1
