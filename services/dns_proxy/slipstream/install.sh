source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh

# https://github.com/EndPositive/slipstream
# Package name expected in packages.lock once pinned; soft-fail if missing.
force=""
[[ -x ./slipstream-server ]] || force=force
if download_package slipstream slipstream-server "" $force; then
    chmod +x slipstream-server
    set_installed_version slipstream
elif [[ ! -x ./slipstream-server ]]; then
    echo "WARN: slipstream-server binary not installed (add slipstream to packages.lock)" >&2
fi
chown dns_proxy:dns_proxy slipstream-server 2>/dev/null || true
