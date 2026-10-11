#!/bin/bash
# Regenerate the configs that change with the user list, then reload those services.
# Output and errors are kept in the log dir: apply-users.out.log and apply-users.err.log.
cd /opt/hiddify-manager
source /opt/hiddify-manager/scripts/common/utils.sh

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run by root" >&2
    exit 1
fi

apply_users() {
    ensure_generated_permissions
    echo "Dumping user configs into $HIDDIFY_GENERATED"
    dump_server_configs "xray,hiddify-core,wireguard,telemt" || {
        echo "Failed to dump user configs into $HIDDIFY_GENERATED" >&2
        return 1
    }
    echo "Reloading services"
    ensure_generated_permissions
    for svc in xray hiddify-core wireguard telegram/telemt; do 
        echo "Reloading $svc"
        run_timed "$svc" bash "$HIDDIFY_SERVICES/$svc/reload.sh" & 
    done
    echo "Waiting for services to reload"
    wait
    echo "Services reloaded"
}

run_logged apply-users apply_users
