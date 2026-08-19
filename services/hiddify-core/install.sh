source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh
rm -rf configs/*.template

# latest= #$(get_release_version hiddify-hiddify-core)
version="" #use specific version if needed otherwise it will use the latest



download_package singbox sb.tar.gz $version
if [ "$?" == "0"  ] || ! is_installed ./hiddify-core; then
    tar -xzf sb.tar.gz  || exit 1
    cp -f hiddify-core-*/* . 2>/dev/null || exit 2
    rm -r sb.zip hiddify-core-* 2>/dev/null || exit 3
    chown root:root hiddify-core || exit 4
    chmod +x hiddify-core || exit 5
    ln -sf /opt/hiddify-manager/services/hiddify-core/hiddify-core /usr/bin/hiddify-core || exit 6
    rm geosite.db 2>/dev/null 
    set_installed_version singbox $version
fi
