cd $(dirname -- "$0")
source /opt/hiddify-manager/scripts/common/utils.sh
source ./cert_utils.sh

domains=$(cat /opt/hiddify-manager/data/current.json | jq -r '.domains[] | select(.mode | IN("direct", "cdn", "worker", "relay", "auto_cdn_ip", "old_xtls_direct", "sub_link_only")) | .domain')
domains=$(cat /opt/hiddify-manager/data/current.json | jq -r '.domains[] | select(.mode | IN("direct",   "relay", "old_xtls_direct", "sub_link_only")) | .domain')

for d in $domains; do
    get_cert $d &
done
wait
stop_nginx_acme

domains=$(cat /opt/hiddify-manager/data/current.json | jq -r '.domains[] | select(.mode | IN("fake")) | .domain')
for d in $domains; do
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