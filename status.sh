#!/bin/bash
# Thin shim: commander.py status path. init.sh writes log/system/status.log.
cd "$(dirname -- "$0")"
exec ./init.sh status
