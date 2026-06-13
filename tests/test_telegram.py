"""Tests for the dispatch and wiring helpers in hiddify_manager.modules.telegram."""
import os
from unittest.mock import patch, MagicMock

from hiddify_manager.modules import telegram


def test_install_skips_when_telegram_lib_unset(tmp_path):
    """No telegram_lib in hconfigs is a no-op (matches install.sh.j2 guard)."""
    cfg = {"hconfigs": {}}
    py_handler = MagicMock()
    tgo_handler = MagicMock()
    with patch.object(telegram, "_BACKENDS", {"python": py_handler, "tgo": tgo_handler}), \
         patch.object(telegram, "hiddify_config", return_value=cfg), \
         patch.object(telegram, "_disable_legacy"):
        telegram.install()
    py_handler.assert_not_called()
    tgo_handler.assert_not_called()


def test_install_warns_on_unknown_backend(tmp_path):
    cfg = {"hconfigs": {"telegram_lib": "mystery"}}
    with patch.object(telegram, "hiddify_config", return_value=cfg), \
         patch.object(telegram, "_disable_legacy"), \
         patch.object(telegram, "log") as mlog:
        telegram.install()
    mlog.warning.assert_called()
    # the warning mentions the unknown backend name
    msgs = " ".join(call.args[0] for call in mlog.warning.call_args_list)
    assert "mystery" in msgs


def test_install_dispatches_to_python_backend(tmp_path):
    cfg = {"hconfigs": {"telegram_lib": "python"}}
    lib_dir = tmp_path / "python"
    lib_dir.mkdir()
    handler = MagicMock()
    with patch.object(telegram, "_BACKENDS", {"python": handler}), \
         patch.object(telegram, "hiddify_config", return_value=cfg), \
         patch.object(telegram, "_disable_legacy"), \
         patch.object(telegram, "_module_dir", return_value=str(tmp_path)):
        telegram.install()
    handler.assert_called_once_with(str(lib_dir), cfg)


def test_install_skips_when_lib_dir_missing(tmp_path):
    """telegram_lib points at a subdir that doesn't exist → warn, don't crash."""
    cfg = {"hconfigs": {"telegram_lib": "python"}}
    handler = MagicMock()
    with patch.object(telegram, "_BACKENDS", {"python": handler}), \
         patch.object(telegram, "hiddify_config", return_value=cfg), \
         patch.object(telegram, "_disable_legacy"), \
         patch.object(telegram, "_module_dir", return_value=str(tmp_path)):
        telegram.install()
    handler.assert_not_called()


def test_wire_service_chmods_matching_files(tmp_path):
    """_wire_service should 0600 every file matching secret_glob."""
    (tmp_path / "config.py").write_text("PORT=1001")
    (tmp_path / "config.py.j2").write_text("PORT=...")
    (tmp_path / "ignore.toml").write_text("x=1")  # different glob, should not chmod
    os.chmod(tmp_path / "config.py", 0o644)
    os.chmod(tmp_path / "config.py.j2", 0o644)
    os.chmod(tmp_path / "ignore.toml", 0o644)

    with patch.object(telegram, "run_cmd"):
        telegram._wire_service(str(tmp_path), "*.py*")

    assert oct((tmp_path / "config.py").stat().st_mode)[-3:] == "600"
    assert oct((tmp_path / "config.py.j2").stat().st_mode)[-3:] == "600"
    # not matched by the glob, mode unchanged
    assert oct((tmp_path / "ignore.toml").stat().st_mode)[-3:] == "644"
