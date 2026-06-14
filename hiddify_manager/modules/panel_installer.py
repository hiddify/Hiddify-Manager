"""
Panel package installer / updater.

Ports common/hiddify_installer.sh::update_panel — the dispatch that
installs the hiddifypanel python package per branch/mode. The 5 modes
mirror the bash exactly:

  release    pypi latest (the default for end users)
  beta       pypi latest --pre
  dev/develop git+https://github.com/hiddify/HiddifyPanel  (HEAD)
  v<tag>     git+https://github.com/hiddify/HiddifyPanel@<tag>
  docker     pip install /opt/hiddify-manager/hiddify-panel/src

Each mode stops the panel services first so an in-flight upgrade
doesn't race a live process holding a now-stale module path.

Not migrated: get_release_version / get_commit_version / "is an
update needed" version probing. Pip handles the no-op fast enough
that the extra GitHub round-trip didn't earn its complexity.
"""
import os

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import VENV_DIR, PROJECT_ROOT
from hiddify_manager.utils.shell import run_cmd


PANEL_GIT = "git+https://github.com/hiddify/HiddifyPanel"
PANEL_PYPI = "hiddifypanel"
PANEL_UNITS = ("hiddify-panel.service", "hiddify-panel-background-tasks.service")
SUPPORTED_MODES = ("release", "beta", "dev", "develop", "docker")


def _pip(*args, check=False):
    """Invoke pip from the project venv with the given trailing args."""
    venv_pip = os.path.join(VENV_DIR, "bin", "pip")
    return run_cmd([venv_pip, *args], check=check)


def _disable_panel_services():
    """Stop the panel units so the new package code is what next start picks up."""
    for unit in PANEL_UNITS:
        run_cmd(["systemctl", "stop", unit], check=False)


def _install_release():
    _pip("install", "-U", "wheel", PANEL_PYPI)


def _install_beta():
    _pip("install", "-U", "--pre", PANEL_PYPI)


def _install_dev():
    # --force-reinstall + --no-deps first to make sure the panel package
    # itself updates even when deps are already at their tip; then a
    # regular install picks up any new dependency.
    _pip("install", "-U", "--force-reinstall", "--no-deps", PANEL_GIT)
    _pip("install", PANEL_GIT)


def _install_tag(tag):
    ref = f"{PANEL_GIT}@{tag}"
    _pip("install", "-U", "--force-reinstall", "--no-deps", ref)
    _pip("install", ref)


def _install_docker():
    src = os.path.join(PROJECT_ROOT, "hiddify-panel", "src")
    if not os.path.isdir(src):
        log.error(f"panel_installer: docker mode requires {src}, not found")
        return False
    _pip("install", src)
    return True


def update_panel(mode="release"):
    """
    Install or upgrade the hiddifypanel package per `mode`. Returns
    True on success, False otherwise. Always stops the panel units
    before pip so in-flight requests don't lock paths under
    site-packages/.
    """
    mode = (mode or "release").lower()

    if mode not in SUPPORTED_MODES and not mode.startswith("v"):
        log.error(
            f"panel_installer: unknown mode {mode!r}; expected one of "
            f"{SUPPORTED_MODES} or v<tag>"
        )
        return False

    log.info(f"panel_installer: updating panel in {mode!r} mode")
    _disable_panel_services()

    if mode == "release":
        _install_release()
    elif mode == "beta":
        _install_beta()
    elif mode in ("dev", "develop"):
        _install_dev()
    elif mode == "docker":
        if not _install_docker():
            return False
    elif mode.startswith("v"):
        _install_tag(mode)

    return True
