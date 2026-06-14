#!/bin/bash
# Thin shim: the real ACME orchestration lives in
# hiddify_manager.modules.cert_issuer. Kept as a .sh so commander.py
# (panel-invoked via sudoers) can keep its absolute-path Command enum
# without churning the panel side.
cd "$(dirname -- "$0")/.."
exec /opt/hiddify-manager/.venv313/bin/python -m hiddify_manager.modules.cert_issuer "$@"
