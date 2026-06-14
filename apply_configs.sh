#!/bin/bash
# Thin shim: panel hits /admin/actions/apply_configs which goes through
# commander.py apply -> this script. Real impl lives in
# hiddify_manager.manager.run_apply_configs.
#
# Log file (log/system/0-install.log, polled by the panel's
# admin_log_api) is written by init.sh itself, not here — that way the
# menu's "Reinstall" and a direct `./init.sh apply-configs` from the
# shell get the same log file the panel expects.
cd "$(dirname -- "$0")"
exec ./init.sh apply-configs
