source /opt/hiddify-manager/common/package_manager.sh
install_package shadowsocks-libev

download_package v2ray-plugin v2ray-plugin-linux.tar.gz 
if [ "$?" == "0"  ] || ! is_installed ./v2ray-plugin_linux; then
    tar xvzf v2ray-plugin-linux.tar.gz || exit 1
    mv v2ray-plugin_linux_$(dpkg --print-architecture) v2ray-plugin_linux ||exit 2
    set_installed_version v2ray-plugin
fi
