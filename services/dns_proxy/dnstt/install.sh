source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh

# VayDNS server — used for custom-proxy proto "dnstt"
# https://github.com/net2share/vaydns
download_package vaydns vaydns-server
if [ "$?" == "0" ] || ! is_installed ./vaydns-server; then
    chmod +x vaydns-server   
    set_installed_version vaydns
fi
