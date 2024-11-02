source /opt/hiddify-manager/common/utils.sh
install_package shadowsocks-libev

if ! is_installed ./v2ray-plugin_linux; then
    declare -A hashes=(
        ["arm64"]="3b26205f39ea815d57005abadba1720c0bbaaa01"
        ["amd64"]="7c042cbc6bfc334ab6479f494801c5bfb19f2938"
    )

    pkg=$(dpkg --print-architecture)
    HASH=${hashes[$pkg]-:hashes[amd64]}
    download_and_check_hash v2ray-plugin-linux.tar.gz https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-$pkg-v1.3.2.tar.gz || return $0
    tar xvzf v2ray-plugin-linux.tar.gz
    mv v2ray-plugin_linux_$(dpkg --print-architecture) v2ray-plugin_linux
fi
