#!/bin/bash
# Run MasterDnsVPN; secrets/config come from custom_proxy.params (dump-server-configs).
set -euo pipefail
INSTANCE="${1:?instance slug required}"
BASE="$(cd "$(dirname "$0")" && pwd)"
CFG_DIR="/opt/hiddify-manager/generated/dns_proxy/masterdns/${INSTANCE}"
TOML="${CFG_DIR}/server_config.toml"
KEY="${CFG_DIR}/encrypt_key.txt"

[[ -f "$TOML" ]] || { echo "missing $TOML" >&2; exit 1; }
[[ -s "$KEY" ]] || { echo "missing encrypt_key.txt (set custom_proxy.params.encrypt_key in panel/init_db)" >&2; exit 1; }
[[ -x "$BASE/bin/masterdnsvpn-server" ]] || { echo "masterdnsvpn-server not installed" >&2; exit 1; }

cd "$CFG_DIR"
exec "$BASE/bin/masterdnsvpn-server" -config server_config.toml
