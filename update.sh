#!/bin/bash
# Thin shim: commander.py update path. Hands off to ./init.sh update.
cd "$(dirname -- "$0")"
exec ./init.sh update "$@"
