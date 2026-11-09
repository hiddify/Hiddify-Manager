#!/bin/bash
source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/warp/usque/utils.sh
# Do not register a Cloudflare account, or keep the tunnel up, until an admin accepted the terms in the panel.
if ! warp_in_use; then
    bash disable.sh
    exit 0
fi
ensure_warp_data_links usque "$(pwd)"
stop_other_warp_backends

if ! check_warp_usque_connection "$(pwd)"; then
    reset_warp_usque_account "$(pwd)"
    if ! check_warp_usque_connection "$(pwd)"; then
        # Last try without a WARP+ key (a bad key leaves the account unusable).
        export WARP_USQUE_SKIP_PLUS=1
        reset_warp_usque_account "$(pwd)"
        if ! check_warp_usque_connection "$(pwd)"; then
            error "!!!!!!!!!!!!!!! WARP (usque) ERROR"
            exit 1
        fi
    fi
fi
