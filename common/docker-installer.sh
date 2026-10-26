#!/bin/bash
# Backward-compat shim: i.hiddify.com/docker/{release,beta,dev} still curls
#   raw.githubusercontent.com/.../main/common/docker-installer.sh
# Forward to scripts/common/docker-installer.sh on the same branch (main keeps
# this path; other branches can override via HIDDIFY_DOCKER_INSTALLER_REF).
set -euo pipefail
ref="${HIDDIFY_DOCKER_INSTALLER_REF:-main}"
url="https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/${ref}/scripts/common/docker-installer.sh"
tmp=$(mktemp)
if ! curl -fsSL -o "$tmp" "$url"; then
    echo "Failed to download $url" >&2
    rm -f "$tmp"
    exit 1
fi
bash "$tmp" "$@"
code=$?
rm -f "$tmp"
exit $code
