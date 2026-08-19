# bash download_wgcf.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh
install_package wireguard-tools
download_package wgcf wgcf
if [ "$?" == "0"  ] || ! is_installed ./wgcf; then
    chmod +x wgcf || exit 1
    set_installed_version wgcf
fi
