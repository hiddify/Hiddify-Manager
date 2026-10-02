# bash download_wgcf.sh
source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/warp/wireguard/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh
ensure_warp_data_links wireguard "$(pwd)"
install_package wireguard-tools resolvconf
download_package wgcf wgcf
if [ "$?" == "0"  ] || ! is_installed ./wgcf; then
    chmod +x wgcf || exit 1
    set_installed_version wgcf
fi
