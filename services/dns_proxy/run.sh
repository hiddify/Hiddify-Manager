#!/bin/bash
# Enable/disable per-domain DNS tunnel units from generated/dns_proxy/{proto}/.
set -euo pipefail
source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/dns_proxy/utils.sh

BASE="$(cd "$(dirname "$0")" && pwd)"
GEN="${HIDDIFY_GENERATED}/dns_proxy"
PROTOS=(dnstt slipstream masterdns)

mkdir -p "$GEN"/{dnstt,slipstream,masterdns}
chown -R dns_proxy:dns_proxy "$GEN" 2>/dev/null || true
# dnstm.json lives at generated/ (not under dns_proxy/)
chown dns_proxy:dns_proxy "${HIDDIFY_GENERATED}/dnstm.json" 2>/dev/null || true

for proto in "${PROTOS[@]}"; do
    dns_proxy_sync_proto_instances "$proto" "$GEN"
done

# DNSTM multi-tunnel router on :53
DNSTM_CFG="${HIDDIFY_GENERATED}/dnstm.json"
if [[ -f "$DNSTM_CFG" ]] && grep -q '"domain"' "$DNSTM_CFG" 2>/dev/null; then
    ln -sfn "$BASE/hiddify-dnstm-router.service" /etc/systemd/system/hiddify-dnstm-router.service
    systemctl daemon-reload
    systemctl enable --now hiddify-dnstm-router.service || systemctl restart hiddify-dnstm-router.service || true
else
    systemctl disable --now hiddify-dnstm-router.service >/dev/null 2>&1 || true
fi
