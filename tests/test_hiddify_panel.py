import os
from unittest.mock import patch

from hiddify_manager.modules import hiddify_panel as panel


def test_read_mysql_password(tmp_path):
    pw_file = tmp_path / "mysql_pass"
    pw_file.write_text("sekret\n")
    with patch.object(panel, "_module_dir", return_value=str(tmp_path)):
        assert panel._read_mysql_password() == "sekret"


def test_read_mysql_password_missing(tmp_path):
    with patch.object(panel, "_module_dir", return_value=str(tmp_path)):
        assert panel._read_mysql_password() is None


def test_read_redis_password(tmp_path):
    conf = tmp_path / "redis.conf"
    conf.write_text(
        "# comment\n"
        "port 6379\n"
        "requirepass V4t75pZ3FjBH1vk\n"
        "maxmemory 100mb\n"
    )
    with patch.object(panel, "_module_dir", return_value=str(tmp_path)):
        assert panel._read_redis_password() == "V4t75pZ3FjBH1vk"


def test_read_redis_password_absent(tmp_path):
    (tmp_path / "redis.conf").write_text("port 6379\n")
    with patch.object(panel, "_module_dir", return_value=str(tmp_path)):
        assert panel._read_redis_password() is None


def test_set_app_cfg_keys_replaces_existing(tmp_path):
    cfg = tmp_path / "app.cfg"
    cfg.write_text(
        "SECRET_KEY=changeme\n"
        "SQLALCHEMY_DATABASE_URI ='old-uri'\n"
        "DEBUG=False\n"
        "REDIS_URI_MAIN = 'old-redis'\n"
    )
    panel._set_app_cfg_keys(
        str(cfg),
        {
            "SQLALCHEMY_DATABASE_URI": "mysql://new",
            "REDIS_URI_MAIN": "redis://new/0",
            "REDIS_URI_SSH": "redis://new/1",
        },
    )
    out = cfg.read_text()
    # old key lines gone
    assert "old-uri" not in out
    assert "old-redis" not in out
    # untouched lines remain
    assert "SECRET_KEY=changeme" in out
    assert "DEBUG=False" in out
    # new values written exactly once
    assert out.count("SQLALCHEMY_DATABASE_URI = 'mysql://new'") == 1
    assert out.count("REDIS_URI_MAIN = 'redis://new/0'") == 1
    assert out.count("REDIS_URI_SSH = 'redis://new/1'") == 1


def test_set_app_cfg_keys_creates_missing(tmp_path):
    cfg = tmp_path / "app.cfg"
    panel._set_app_cfg_keys(str(cfg), {"FOO": "bar"})
    assert cfg.read_text() == "FOO = 'bar'\n"
    assert oct(cfg.stat().st_mode)[-3:] == "600"


def test_set_app_cfg_keys_no_dupes_on_re_run(tmp_path):
    cfg = tmp_path / "app.cfg"
    cfg.write_text("DEBUG=False\n")
    panel._set_app_cfg_keys(str(cfg), {"FOO": "v1"})
    panel._set_app_cfg_keys(str(cfg), {"FOO": "v2"})
    out = cfg.read_text()
    assert out.count("FOO = ") == 1
    assert "FOO = 'v2'" in out
