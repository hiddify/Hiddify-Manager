source /opt/hiddify-manager/scripts/common/utils.sh
source ./wg_utils.sh
install_package wireguard

mkdir -p /etc/wireguard
chmod 660 /etc/wireguard

echo "net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1" >/etc/sysctl.d/wg.conf

if [ "$MODE" != "docker" ]; then
    sysctl --system >/dev/null
fi

systemctl enable "wg-quick@${SERVER_WG_NIC}"
