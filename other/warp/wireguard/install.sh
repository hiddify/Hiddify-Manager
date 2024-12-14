# bash download_wgcf.sh
source /opt/hiddify-manager/common/package_manager.sh
if ! is_installed ./wgcf; then
    download_package wgcf wgcf
    chmod +x wgcf
fi
install_package wireguard-dkms wireguard-tools
