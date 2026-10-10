#!/bin/bash
# Regenerate the configs that change with the user list, then reload those services.
cd /opt/hiddify-manager
source /opt/hiddify-manager/scripts/common/utils.sh

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run by root" >&2
    exit 1
fi

CORES="xray,hiddify-core,wireguard,telemt"

dump_server_configs "$CORES" || {
    echo "Failed to dump user configs into $HIDDIFY_GENERATED" >&2
    exit 1
}

if getent group hiddify-common >/dev/null 2>&1; then
    
    
        chmod -R 640 "$HIDDIFY_GENERATED/"
        chown -R hiddify-panel:hiddify-common "$HIDDIFY_GENERATED/"
    
    
fi


bash "$HIDDIFY_SERVICES/xray/reload.sh" &
bash "$HIDDIFY_SERVICES/hiddify-core/reload.sh" &
bash "$HIDDIFY_SERVICES/wireguard/reload.sh" &
bash "$HIDDIFY_SERVICES/telegram/telemt/reload.sh" &
wait
