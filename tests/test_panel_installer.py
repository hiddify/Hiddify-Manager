"""Tests for hiddify_manager.modules.panel_installer.

The dispatcher is mostly a sequence of pip invocations. We mock run_cmd
and assert which argv shapes get handed to pip per mode.
"""
import os
from unittest.mock import patch

import pytest

from hiddify_manager.modules import panel_installer as pi


# We never want the tests to actually invoke pip or systemctl.
@pytest.fixture(autouse=True)
def _fake_run_cmd():
    with patch.object(pi, "run_cmd") as m:
        yield m


def _pip_invocations(mock):
    """Yield only the arg-list of calls that look like a pip invocation."""
    for c in mock.call_args_list:
        argv = c.args[0]
        if argv and argv[0].endswith("/pip"):
            yield argv


def test_release_runs_pip_install_u_wheel_hiddifypanel(_fake_run_cmd):
    assert pi.update_panel("release") is True
    invocations = list(_pip_invocations(_fake_run_cmd))
    assert len(invocations) == 1
    assert invocations[0][1:] == ["install", "-U", "wheel", "hiddifypanel"]


def test_beta_runs_pip_install_u_pre(_fake_run_cmd):
    assert pi.update_panel("beta") is True
    invocations = list(_pip_invocations(_fake_run_cmd))
    assert invocations[0][1:] == ["install", "-U", "--pre", "hiddifypanel"]


def test_dev_runs_two_pip_invocations_no_deps_then_full(_fake_run_cmd):
    assert pi.update_panel("dev") is True
    invocations = list(_pip_invocations(_fake_run_cmd))
    assert len(invocations) == 2
    assert "--no-deps" in invocations[0]
    assert "--force-reinstall" in invocations[0]
    assert pi.PANEL_GIT in invocations[0]
    # Second invocation has neither --no-deps nor --force-reinstall.
    assert "--no-deps" not in invocations[1]
    assert pi.PANEL_GIT in invocations[1]


def test_develop_is_alias_for_dev(_fake_run_cmd):
    assert pi.update_panel("develop") is True
    invocations = list(_pip_invocations(_fake_run_cmd))
    # Same two-invocation shape as dev
    assert len(invocations) == 2


def test_v_tag_installs_from_git_ref(_fake_run_cmd):
    assert pi.update_panel("v10.20.1") is True
    invocations = list(_pip_invocations(_fake_run_cmd))
    assert len(invocations) == 2
    ref = f"{pi.PANEL_GIT}@v10.20.1"
    assert ref in invocations[0]
    assert ref in invocations[1]


def test_docker_installs_local_src(tmp_path, _fake_run_cmd):
    src = tmp_path / "hiddify-panel" / "src"
    src.mkdir(parents=True)
    with patch.object(pi, "PROJECT_ROOT", str(tmp_path)):
        assert pi.update_panel("docker") is True
    invocations = list(_pip_invocations(_fake_run_cmd))
    assert invocations[0][1:] == ["install", str(src)]


def test_docker_fails_when_src_missing(tmp_path, _fake_run_cmd):
    with patch.object(pi, "PROJECT_ROOT", str(tmp_path)):
        assert pi.update_panel("docker") is False
    # No pip invocations on the failure path
    assert list(_pip_invocations(_fake_run_cmd)) == []


def test_unknown_mode_returns_false_and_does_no_work(_fake_run_cmd):
    with patch.object(pi, "log") as mlog:
        assert pi.update_panel("mystery") is False
    mlog.error.assert_called()
    assert list(_pip_invocations(_fake_run_cmd)) == []


def test_panel_services_are_stopped_before_pip(_fake_run_cmd):
    pi.update_panel("release")
    # The systemctl stop calls happen before any pip invocation.
    actions = [c.args[0] for c in _fake_run_cmd.call_args_list]
    pip_indices = [i for i, a in enumerate(actions) if a and a[0].endswith("/pip")]
    stop_indices = [
        i for i, a in enumerate(actions)
        if a[:2] == ["systemctl", "stop"]
    ]
    assert stop_indices, "expected systemctl stop calls"
    assert max(stop_indices) < min(pip_indices)


def test_mode_case_insensitive(_fake_run_cmd):
    assert pi.update_panel("RELEASE") is True
    # Same shape as test_release
    invocations = list(_pip_invocations(_fake_run_cmd))
    assert invocations[0][1:] == ["install", "-U", "wheel", "hiddifypanel"]


def test_default_mode_is_release(_fake_run_cmd):
    assert pi.update_panel() is True
    invocations = list(_pip_invocations(_fake_run_cmd))
    assert invocations[0][1:] == ["install", "-U", "wheel", "hiddifypanel"]
