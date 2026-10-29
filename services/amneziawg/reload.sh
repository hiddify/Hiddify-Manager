#!/bin/bash
cd "$(dirname -- "$0")"
source ./awg_utils.sh

# apply_users reloads every service: nothing to do when AmneziaWG is off (its unit is disabled by disable.sh).
if ! systemctl is-enabled --quiet "$AWG_UNIT" 2>/dev/null; then
    exit 0
fi

link_awg_config || exit 1

systemctl try-reload-or-restart "$AWG_UNIT"
