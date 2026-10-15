source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh

# https://github.com/masterking32/MasterDnsVPN
# Package name expected in packages.lock once pinned; soft-fail if missing.
force=""
[[ -x ./bin/masterdnsvpn-server ]] || force=force
if download_package masterdns masterdnsvpn-server.zip "" $force; then
    install_package unzip
    mkdir -p bin
    unzip -o masterdnsvpn-server.zip -d bin
    mv -f bin/MasterDns* bin/masterdnsvpn-server
    chmod +x bin/masterdnsvpn-server
    set_installed_version masterdns
elif [[ ! -x ./bin/masterdnsvpn-server ]]; then
    echo "WARN: masterdnsvpn-server binary not installed (add masterdnsvpn to packages.lock)" >&2
fi
chown dns_proxy:dns_proxy bin/masterdnsvpn-server 2>/dev/null || true
