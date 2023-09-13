# bash download_wgcf.sh
source ../../common/utils.sh
if ! is_installed wgcf; then
    curl -fsSL git.io/wgcf.sh | sudo bash
fi
install_package wireguard-dkms wireguard-tools resolvconf
