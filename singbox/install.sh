source ../common/utils.sh
source ../common/package_manager.sh
rm -rf configs/*.template

# latest= #$(get_release_version hiddify-sing-box)
version="" #use specific version if needed otherwise it will use the latest
download_package singbox sb.zip $version

function install_singbox() {
    install_package unzip 
    unzip -o sb.zip > /dev/null || return 1
    cp -f sing-box-*/sing-box . 2>/dev/null || return 2
    rm -r sb.zip sing-box-* 2>/dev/null || return 3
    chown root:root sing-box || return 4
    chmod +x sing-box || return 5
    ln -sf /opt/hiddify-manager/singbox/sing-box /usr/bin/sing-box || return 6
    rm geosite.db 2>/dev/null 
}
if [ "$?" == "0"  ] || ! is_installed ./sing-box; then
    if install_singbox; then
        set_installed_version singbox $version
    else
        echo "Failed to install singbox $?"
        exit 1    
    fi
fi
