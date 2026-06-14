#!/bin/bash
# Thin shim: commander.py restart-services path. init.sh writes
# log/system/restart.log.
cd "$(dirname -- "$0")"
exec ./init.sh restart
