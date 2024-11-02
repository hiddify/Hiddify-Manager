# bash download_wgcf.sh
source /opt/hiddify-manager/common/utils.sh
if ! is_installed ./wgcf; then
    declare -A hashes=(
        ["arm64"]="d99d472b74a69f349c7cb02e26664cbc396014d3"
        ["amd64"]="72afecd7ddd5029532038415609a957ee3cc8147"
    )

    pkg=$(dpkg --print-architecture)
    HASH=${hashes[$pkg]-:hashes[amd64]}

    download_and_check_hash wgcf https://github.com/ViRb3/wgcf/releases/download/v2.2.23/wgcf_2.2.23_linux_$pkg || return $0
    chmod +x wgcf
    
    
fi
install_package wireguard-dkms wireguard-tools
