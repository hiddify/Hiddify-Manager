source /opt/hiddify-manager/common/package_manager.sh
install_package shadowsocks-libev

if ! is_installed ./v2ray-plugin_linux; then
    download_package v2ray-plugin v2ray-plugin-linux.tar.gz 
    tar xvzf v2ray-plugin-linux.tar.gz
    mv v2ray-plugin_linux_$(dpkg --print-architecture) v2ray-plugin_linux
fi
