#!/bin/bash
# Run vaydns-server; argv comes from generated args (server_config → include_path).
set -euo pipefail
INSTANCE="${1:?instance slug required}"
BASE="$(cd "$(dirname "$0")" && pwd)"
CFG_DIR="/opt/hiddify-manager/generated/dns_proxy/dnstt/${INSTANCE}"
ARGS_FILE="${CFG_DIR}/args"

[[ -f "$ARGS_FILE" ]] || { echo "missing $ARGS_FILE" >&2; exit 1; }
[[ -x "$BASE/vaydns-server" ]] || { echo "vaydns-server not installed" >&2; exit 1; }

# One argv token per line; skip blank lines and template comments.
mapfile -t ARGS < <(grep -vE '^[[:space:]]*(#|$)' "$ARGS_FILE")
exec "$BASE/vaydns-server" "${ARGS[@]}"
