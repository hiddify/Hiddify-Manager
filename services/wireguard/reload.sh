#!/bin/bash
cd "$(dirname -- "$0")"
source ./wg_utils.sh

generated="/opt/hiddify-manager/generated/wireguard.conf"
conf="/etc/wireguard/${SERVER_WG_NIC}.conf"
unit="wg-quick@${SERVER_WG_NIC}"

if [ ! -s "$generated" ]; then
    echo "Missing $generated"
    exit 1
fi

allow_wg_quick_read "$generated"
mkdir -p /etc/wireguard
ln -sfn "$generated" "$conf"

systemctl try-reload-or-restart "$unit"
