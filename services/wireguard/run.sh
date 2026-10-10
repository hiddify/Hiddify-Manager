source ./wg_utils.sh

generated="/opt/hiddify-manager/generated/wireguard.conf"
conf="/etc/wireguard/${SERVER_WG_NIC}.conf"

if [ ! -s "$generated" ]; then
    echo "Missing $generated"
    exit 1
fi

# wg-quick may only read /etc/wireguard. The link resolves to the generated file.
allow_wg_quick_read "$generated"

mkdir -p /etc/wireguard
ln -sfn "$generated" "$conf"

if systemctl is-active --quiet "wg-quick@${SERVER_WG_NIC}"; then
    systemctl reload "wg-quick@${SERVER_WG_NIC}"
else
    systemctl enable --now "wg-quick@${SERVER_WG_NIC}"
fi
