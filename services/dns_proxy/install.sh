source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh

BASE="$(cd "$(dirname "$0")" && pwd)"

useradd --system --no-create-home dns_proxy 2>/dev/null || true

source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh

# dnstm router binary (shared by dns_proxy)
download_package dnstm dnstm
if [ "$?" == "0" ] || ! is_installed ./dnstm; then
    chmod +x dnstm
    set_installed_version dnstm
fi


bash "$BASE/dnstt/install.sh"
bash "$BASE/slipstream/install.sh"
bash "$BASE/masterdns/install.sh"

# Symlink root; protocol/instance dirs are created by panel dump (dns_proxy_dump).
mkdir -p "$HIDDIFY_GENERATED"
ln -sfn "$HIDDIFY_GENERATED/dns_proxy" "$BASE/generated"

# Install systemd template units + router
ln -sfn "$BASE/dnstt/hiddify-dnstt@.service" /etc/systemd/system/hiddify-dnstt@.service
ln -sfn "$BASE/slipstream/hiddify-slipstream@.service" /etc/systemd/system/hiddify-slipstream@.service
ln -sfn "$BASE/masterdns/hiddify-masterdns@.service" /etc/systemd/system/hiddify-masterdns@.service
ln -sfn "$BASE/hiddify-dnstm-router.service" /etc/systemd/system/hiddify-dnstm-router.service
systemctl daemon-reload
