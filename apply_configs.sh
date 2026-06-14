#!/bin/bash
# Thin shim: panel hits /admin/actions/apply_configs which invokes
# commander.py apply, which execs this script. Real impl lives in
# hiddify_manager.manager.run_apply_configs (./init.sh apply-configs).
cd "$(dirname -- "$0")"
exec ./init.sh apply-configs
