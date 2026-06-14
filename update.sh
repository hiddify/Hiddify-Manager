#!/bin/bash
# Thin shim: commander.py update path. init.sh writes log/system/update.log.
cd "$(dirname -- "$0")"
exec ./init.sh update "$@"
