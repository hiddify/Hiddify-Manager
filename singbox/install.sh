source ../common/utils.sh
source ../common/package_manager.sh
rm -rf configs/*.template

# latest= #$(get_release_version hiddify-sing-box)
version="" #use specific version if needed otherwise it will use the latest
download_package singbox sb.zip $version
if [ "$?" == "0"  ] || ! is_installed ./sing-box; then
    unzip -o sb.zip > /dev/null
    cp -f sing-box-*/sing-box . 2>/dev/null
    rm -r sb.zip sing-box-* 2>/dev/null
    chown root:root sing-box
    chmod +x sing-box
    ln -sf /opt/hiddify-manager/singbox/sing-box /usr/bin/sing-box
    rm geosite.db 2>/dev/null

    set_installed_version xray $version
fi
