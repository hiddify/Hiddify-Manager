#!/bin/bash
# Run slipstream-server; argv comes from custom_proxy.params via generated args file.
set -euo pipefail
INSTANCE="${1:?instance slug required}"
BASE="$(cd "$(dirname "$0")" && pwd)"
CFG_DIR="/opt/hiddify-manager/generated/dns_proxy/slipstream/${INSTANCE}"
ARGS_FILE="${CFG_DIR}/args"

[[ -f "$ARGS_FILE" ]] || { echo "missing $ARGS_FILE" >&2; exit 1; }
[[ -x "$BASE/slipstream-server" ]] || { echo "slipstream-server not installed" >&2; exit 1; }

mapfile -t ARGS < "$ARGS_FILE"
exec "$BASE/slipstream-server" "${ARGS[@]}"
