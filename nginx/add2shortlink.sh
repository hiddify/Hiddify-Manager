#!/bin/bash
# Thin shim: real implementation in hiddify_manager.modules.short_link.
# Kept as a .sh so commander.py's Command enum doesn't churn.
cd "$(dirname -- "$0")/.."
exec /opt/hiddify-manager/.venv313/bin/python -m hiddify_manager.modules.short_link "$@"
