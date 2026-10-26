cd "$(dirname -- "$0")"
source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/warp/usque/utils.sh

function main() {
    local cfg
    cfg=$(warp_usque_config)
    warning "- Warp Status (usque):"
    if [ -x ./usque ] && [ -f "$cfg" ]; then
        warning "  - Account:"
        ./usque -c "$cfg" account info 2>&1 | sed 's|^|\t|' || true
    fi
    warning "  - Network:"
    curl -s --interface warp --connect-timeout 1 http://ip-api.com?fields=country,city,org,query | sed 's|^|      | ; /[{}]/d'
}

mkdir -p /opt/hiddify-manager/data/log/
main |& tee /opt/hiddify-manager/data/log/warp.log
