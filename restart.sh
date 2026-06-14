#!/bin/bash
# Thin shim: commander.py restart-services path. Hands off to
# ./init.sh restart (services.restart waves + rich status table).
cd "$(dirname -- "$0")"
exec ./init.sh restart
