
source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/warp/utils.sh
cd "$(dirname -- "$0")"
ensure_warp_data_links singbox "$(pwd)"

wget -N https://raw.githubusercontent.com/fscarmen/warp/main/api.sh && bash api.sh -u -f wgcf-account.toml

mv wgcf-account.toml wgcf-account.toml.backup
ensure_warp_data_links singbox "$(pwd)"
# curl --connect-timeout 1 -Lo wgcf.zip https://api.zeroteam.top/warp?format=wgcf
# unzip -o wgcf.zip
bash run.sh
