"""
Uninstall hiddify-manager-managed units and crons.

Replaces uninstall.sh. `purge=True` is the legacy `uninstall.sh purge`
flag and additionally drops the panel package + a handful of apt
packages we know are pulled in by the install path.
"""
import glob
import os

from hiddify_manager.modules.services import discover_units
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import PROJECT_ROOT
from hiddify_manager.utils.shell import run_cmd


# Legacy uninstall.sh purge step apt-removed these packages explicitly.
PURGE_APT_PACKAGES = ["nginx", "gunicorn", "mariadb-*"]


def run(purge=False):
    """
    Kill + disable every hiddify-managed unit, then remove cron entries.
    If purge=True, also apt-purge a known set of packages.
    """
    units = discover_units()
    # Add the legacy "netdata" name even if we never installed it; the bash
    # uninstall iterated over both modern and historic unit names.
    if "netdata" not in units:
        units.append("netdata")

    for unit in units:
        run_cmd(["systemctl", "kill", unit], check=False)
        run_cmd(["systemctl", "disable", unit], check=False)

    for cron in glob.glob("/etc/cron.d/hiddify*"):
        try:
            os.remove(cron)
        except OSError as e:
            log.warning(f"uninstall: could not remove {cron}: {e}")
    run_cmd(["service", "cron", "reload"], check=False)

    if purge:
        log.info("uninstall: purging panel + apt packages")
        run_cmd(["apt-get", "purge", "-y", *PURGE_APT_PACKAGES], check=False)
        # The legacy script did `rm -rf hiddify-panel` and `rm -rf *` from
        # the project root, but the wholesale rm -rf * is an obvious foot-
        # gun (it wipes the script that's running it). Only purge the
        # panel subdir explicitly.
        panel_dir = os.path.join(PROJECT_ROOT, "hiddify-panel")
        if os.path.isdir(panel_dir):
            run_cmd(["rm", "-rf", panel_dir], check=False)
        log.info("uninstall: panel removed. The hiddify-manager checkout is left in place — delete it manually if you want a fresh start.")
