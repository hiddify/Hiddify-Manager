"""Tests for hiddify_manager.modules.services."""
from types import SimpleNamespace
from unittest.mock import patch

from hiddify_manager.modules import services


def _result(returncode=0, stdout=""):
    return SimpleNamespace(returncode=returncode, stdout=stdout)


def test_unit_name_strips_path_and_suffix():
    assert services._unit_name("other/redis/hiddify-redis.service") == "hiddify-redis"
    assert services._unit_name("hiddify-panel.service") == "hiddify-panel"
    # already-bare unit name passes through
    assert services._unit_name("mariadb") == "mariadb"


def test_discover_units_picks_up_files_and_externals(tmp_path, monkeypatch):
    # Stub the glob root with a temp project tree.
    (tmp_path / "nginx").mkdir()
    (tmp_path / "other" / "redis").mkdir(parents=True)
    (tmp_path / "nginx" / "hiddify-nginx.service").write_text("[Unit]")
    (tmp_path / "other" / "redis" / "hiddify-redis.service").write_text("[Unit]")
    # noise: a non-service file
    (tmp_path / "nginx" / "nginx.conf").write_text("x")

    monkeypatch.setattr(
        services, "_SERVICE_GLOBS",
        (str(tmp_path / "**" / "*.service"),),
    )
    units = services.discover_units()
    assert "hiddify-nginx" in units
    assert "hiddify-redis" in units
    # external units always added
    for u in services.EXTERNAL_UNITS:
        assert u in units


def test_discover_units_skips_venv_paths(tmp_path, monkeypatch):
    """Service files under .venv* shouldn't be picked up (panel deps ship some)."""
    (tmp_path / ".venv313").mkdir()
    (tmp_path / ".venv313" / "noise.service").write_text("[Unit]")
    monkeypatch.setattr(
        services, "_SERVICE_GLOBS",
        (str(tmp_path / "**" / "*.service"),),
    )
    units = services.discover_units()
    assert "noise" not in units


def test_should_skip_warp_when_disabled():
    cfg = {"hconfigs": {"warp_mode": "disable"}}
    with patch.object(services, "hiddify_config", return_value=cfg):
        assert services._should_skip("wg-quick@warp") is True


def test_should_not_skip_warp_when_enabled():
    cfg = {"hconfigs": {"warp_mode": "on"}}
    with patch.object(services, "hiddify_config", return_value=cfg):
        assert services._should_skip("wg-quick@warp") is False


def test_should_skip_returns_false_for_other_units():
    with patch.object(services, "hiddify_config", return_value={}):
        assert services._should_skip("hiddify-nginx") is False


def test_restart_unit_skips_disabled_units():
    with patch.object(services, "_is_enabled", return_value=False), \
         patch.object(services, "run_cmd") as m:
        result = services._restart_unit("hiddify-nginx")
    assert result is None
    # no systemctl restart was invoked
    assert not any(c.args[0][:2] == ["systemctl", "restart"] for c in m.call_args_list)


def test_restart_unit_invokes_systemctl_restart_when_enabled():
    with patch.object(services, "_is_enabled", return_value=True), \
         patch.object(services, "_is_active", side_effect=["active", "active"]), \
         patch.object(services, "run_cmd") as m:
        row = services._restart_unit("hiddify-nginx")
    assert row == ("hiddify-nginx", "active", "active")
    assert any(c.args[0] == ["systemctl", "restart", "hiddify-nginx"] for c in m.call_args_list)


def test_restart_unit_skips_warp_when_disabled():
    """warp_mode=disable should short-circuit before systemctl restart."""
    with patch.object(services, "hiddify_config", return_value={"hconfigs": {"warp_mode": "disable"}}), \
         patch.object(services, "_is_enabled", return_value=True), \
         patch.object(services, "run_cmd") as m:
        assert services._restart_unit("wg-quick@warp") is None
    assert not any(c.args[0][:2] == ["systemctl", "restart"] for c in m.call_args_list)


def test_status_only_reports_enabled_units():
    """An enabled unit shows up; a disabled unit doesn't."""
    with patch.object(services, "discover_units", return_value=["a", "b"]), \
         patch.object(services, "_should_skip", return_value=False), \
         patch.object(services, "_is_enabled", side_effect=lambda u: u == "a"), \
         patch.object(services, "_is_active", return_value="active"):
        rows = services.status()
    assert rows == [("a", "active")]


def test_restart_runs_panel_after_others():
    """The wave ordering: others → panel → cli."""
    discovered = ["hiddify-nginx", "hiddify-panel", "hiddify-panel-background-tasks", "hiddify-cli"]
    order = []
    def fake_restart(unit):
        order.append(unit)
        return (unit, "active", "active")
    with patch.object(services, "discover_units", return_value=discovered), \
         patch.object(services, "_restart_unit", side_effect=fake_restart):
        services.restart()
    # Find indices of panel/cli relative to nginx
    nginx_i = order.index("hiddify-nginx")
    panel_i = order.index("hiddify-panel")
    cli_i = order.index("hiddify-cli")
    assert nginx_i < panel_i < cli_i
