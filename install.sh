#!/bin/bash
# Thin shim: commander.py install path. Legacy install.sh accepted
# "apply_configs" / "apply_users" subcommands; route those to the
# matching ./init.sh commands. init.sh handles the log file teeing.
cd "$(dirname -- "$0")"
case "${1:-}" in
    apply_configs) shift; exec ./init.sh apply-configs "$@" ;;
    apply_users)   shift; exec ./init.sh apply-users   "$@" ;;
    *)             exec ./init.sh install              "$@" ;;
esac
