#!/bin/bash
# Enable/disable per-domain DNS tunnel units from generated/dns_proxy/{proto}/.
set -euo pipefail
source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/dns_proxy/utils.sh

BASE="$(cd "$(dirname "$0")" && pwd)"
GEN="${HIDDIFY_GENERATED}/dns_proxy"
PROTOS=(dnstt slipstream masterdns)

mkdir -p "$GEN"/{dnstt,slipstream,masterdns}
dns_proxy_normalize_layout "$GEN"
dns_proxy_write_masterdns_keys "$GEN"
dns_proxy_fix_permissions "$GEN"

for proto in "${PROTOS[@]}"; do
    dns_proxy_sync_proto_instances "$proto" "$GEN"
done

# DNSTM multi-tunnel router on :53
if dns_proxy_write_router_config "${HIDDIFY_GENERATED}/dnstm.json" "${HIDDIFY_GENERATED}/dnstm"; then
    ln -sfn "$BASE/hiddify-dnstm-router.service" /etc/systemd/system/hiddify-dnstm-router.service
    systemctl daemon-reload
    systemctl enable hiddify-dnstm-router.service >/dev/null 2>&1 || true
    # Always restart: dnstm only reads its routes at startup.
    systemctl restart hiddify-dnstm-router.service || true
else
    systemctl disable --now hiddify-dnstm-router.service >/dev/null 2>&1 || true
fi
