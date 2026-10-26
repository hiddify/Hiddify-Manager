#!/bin/bash
cd "$(dirname -- "$0")"
source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/warp/usque/utils.sh
ensure_warp_data_links usque "$(pwd)"

get_current_warp_ip() {
    curl -s --interface warp --connect-timeout 0.5 http://v4.ident.me
}

change_warp_ip() {
    if [ ! -f "$(warp_usque_config)" ]; then
        bash run.sh
        return
    fi
    reset_warp_usque_account "$(pwd)"
    bash run.sh
}

current_warp_ip=$(get_current_warp_ip)
echo "Your current WARP IP is $current_warp_ip"

change_warp_ip
new_warp_ip=$(get_current_warp_ip)
until [ "$current_warp_ip" != "$new_warp_ip" ] && [ -n "$new_warp_ip" ]; do
    echo "new IP '$new_warp_ip' is the same as the previous one '$current_warp_ip'"
    sleep 1
    change_warp_ip
    new_warp_ip=$(get_current_warp_ip)
done
echo "WARP IP has been updated from '$current_warp_ip' to '$new_warp_ip'"
