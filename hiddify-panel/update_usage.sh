#!/bin/bash
# Thin shim: real implementation in hiddify_manager.modules.update_usage.
# Kept as a .sh so commander.py's Command.update_usage path doesn't churn.
cd "$(dirname -- "$0")/.."
exec /opt/hiddify-manager/.venv313/bin/python -m hiddify_manager.modules.update_usage "$@"
