cd $(dirname -- "$0")
source /opt/hiddify-manager/scripts/common/utils.sh
source ./cert_utils.sh

# ACME for domains that need a real cert: fake_mode=valid and a public-facing mode.
# Matches Domain.need_valid_ssl (also dumped on current.json when dump_ports=true).
domains=$(jq -r '
  .domains[]
  | select(.fake_mode == "valid")
  | select(.mode | IN("direct", "cdn", "worker", "relay", "auto_cdn_ip", "old_xtls_direct", "sub_link_only"))
  | select(.domain != null and .domain != "" and (.domain | contains("*") | not))
  | .domain
' /opt/hiddify-manager/data/current.json)

for d in $domains; do
    get_cert $d &
done
wait
stop_nginx_acme

fake_domains=$(jq -r '
  .domains[]
  | select(.fake_mode == "fake")
  | select(.domain != null and .domain != "")
  | .domain
' /opt/hiddify-manager/data/current.json)
for d in $fake_domains; do
    get_self_signed_cert $d &
done
wait

for f in /opt/hiddify-manager/data/ssl/*.crt; do
    d=$(basename "$f" .crt)
    get_self_signed_cert $d &
done
wait
set_files_in_folder_readable_to_hiddify_common_group /opt/hiddify-manager/data/ssl
systemctl reload hiddify-haproxy
systemctl reload hiddify-core
# systemctl reload hiddify-xray