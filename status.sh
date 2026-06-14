#!/bin/bash
# Thin shim: commander.py status path. Hands off to ./init.sh status.
cd "$(dirname -- "$0")"
exec ./init.sh status
