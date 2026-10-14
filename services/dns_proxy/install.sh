source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh

BASE="$(cd "$(dirname "$0")" && pwd)"

useradd --system --no-create-home dns_proxy 2>/dev/null || true
usermod -aG hiddify-common dns_proxy 2>/dev/null || true

source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh

# dnstm router binary (shared by dns_proxy)
# Force the download when the binary is gone: packages.db (data/) outlives services/.
force=""
[[ -x ./dnstm ]] || force=force
if download_package dnstm dnstm "" $force; then
    chmod +x dnstm
    set_installed_version dnstm
elif [[ ! -x ./dnstm ]]; then
    echo "WARN: dnstm binary not installed" >&2
fi

# Each installer downloads into its cwd, and run-instance.sh looks next to itself.
for proto in dnstt slipstream masterdns; do
    (cd "$BASE/$proto" && bash install.sh)
done

# Symlink root; protocol/instance dirs are created by panel dump (dns_proxy_dump).
mkdir -p "$HIDDIFY_GENERATED"
ln -sfn "$HIDDIFY_GENERATED/dns_proxy" "$BASE/generated"

# Install systemd template units + router
ln -sfn "$BASE/dnstt/hiddify-dnstt@.service" /etc/systemd/system/hiddify-dnstt@.service
ln -sfn "$BASE/slipstream/hiddify-slipstream@.service" /etc/systemd/system/hiddify-slipstream@.service
ln -sfn "$BASE/masterdns/hiddify-masterdns@.service" /etc/systemd/system/hiddify-masterdns@.service
ln -sfn "$BASE/hiddify-dnstm-router.service" /etc/systemd/system/hiddify-dnstm-router.service
systemctl daemon-reload
