source ./wg_utils.sh

systemctl stop "wg-quick@${SERVER_WG_NIC}"
systemctl disable "wg-quick@${SERVER_WG_NIC}"