#!/bin/bash
# Self-check for strip_warp_ipv6_address (GNU sed, run on Linux): bash services/warp/wireguard/test_utils.sh
set -e
eval "$(sed -n '/^function strip_warp_ipv6_address/,/^}/p' "$(dirname -- "$0")/utils.sh")"
f=$(mktemp)
trap 'rm -f "$f"' EXIT
for line in \
    "Address = 172.16.0.2/32, 2606:4700:110:8e8b:8d00:90d2:8b82:91df/128" \
    "Address = 2606:4700:110:8e8b::1/128, 172.16.0.2/32" \
    "Address = 172.16.0.2/32"; do
    printf '[Interface]\n%s\nMTU = 1320\n' "$line" >"$f"
    strip_warp_ipv6_address "$f"
    grep -qx 'Address = 172.16.0.2/32' "$f" || { echo "FAIL: $line"; cat "$f"; exit 1; }
done
echo ok
