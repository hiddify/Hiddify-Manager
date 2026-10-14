source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh

# VayDNS server — used for custom-proxy proto "dnstt"
# https://github.com/net2share/vaydns
# packages.db (data/) outlives services/ across release upgrades: force the download
# when the binary is gone, otherwise download_package reports "already downloaded".
force=""
[[ -x ./vaydns-server ]] || force=force
if download_package vaydns vaydns-server "" $force; then
    chmod +x vaydns-server
    set_installed_version vaydns
elif [[ ! -x ./vaydns-server ]]; then
    echo "WARN: vaydns-server binary not installed" >&2
fi
