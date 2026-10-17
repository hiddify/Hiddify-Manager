#!/bin/bash
# Clash Meta (Mihomo) client binary only — no systemd service.
# Used by the panel config tester to run Clash YAML subscriptions natively.
source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh

version="" # use specific version if needed otherwise it will use the latest

download_package clash mihomo.gz $version
if [ "$?" == "0" ] || ! is_installed ./mihomo; then
    gunzip -f mihomo.gz || exit 1
    chown root:root mihomo || exit 2
    chmod +x mihomo || exit 3
    ln -sf /opt/hiddify-manager/services/clash/mihomo /usr/bin/mihomo || exit 4
    set_installed_version clash $version
fi
