#!/bin/bash
# Starts usque nativetun as the "warp" interface (xray / hiddify-core bind to it).
set -e
cd "$(dirname -- "$0")"
source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/warp/usque/utils.sh

cfg=$(warp_usque_config)
if [ ! -f "$cfg" ]; then
    echo "missing $cfg — run services/warp/usque/run.sh first" >&2
    exit 1
fi

args=(nativetun -c "$cfg" -n warp --always-reconnect)
if ! warp_host_has_ipv6; then
    args+=(--no-tunnel-ipv6)
fi
exec ./usque "${args[@]}"
