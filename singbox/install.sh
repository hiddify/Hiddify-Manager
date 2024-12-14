source ../common/utils.sh
source ../common/package_manager.sh
rm -rf configs/*.template

# latest= #$(get_release_version hiddify-sing-box)
version="" #use specific version if needed otherwise it will use the latest



download_package singbox sb.zip $version
if [ "$?" == "0"  ] || ! is_installed ./sing-box; then
    install_package unzip 
    unzip -o sb.zip > /dev/null || exit 1
    cp -f sing-box-*/sing-box . 2>/dev/null || exit 2
    rm -r sb.zip sing-box-* 2>/dev/null || exit 3
    chown root:root sing-box || exit 4
    chmod +x sing-box || exit 5
    ln -sf /opt/hiddify-manager/singbox/sing-box /usr/bin/sing-box || exit 6
    rm geosite.db 2>/dev/null 
    set_installed_version singbox $version
fi
