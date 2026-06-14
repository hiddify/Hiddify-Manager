#!/bin/bash
# Thin shim: commander.py and the legacy `apply-users` route both call
# this path. The legacy install.sh accepted "apply_configs" / "apply_users"
# subcommands; route those to the equivalent python commands, default
# to a full install.
cd "$(dirname -- "$0")"
case "${1:-}" in
    apply_configs) shift; exec ./init.sh apply-configs "$@" ;;
    apply_users)   shift; exec ./init.sh apply-users   "$@" ;;
    *)             exec ./init.sh install              "$@" ;;
esac
