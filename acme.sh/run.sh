source ../common/utils.sh
source ./cert_utils.sh

# domains=$(cat ../current.json | jq -r '.domains[] | select(.mode | IN("direct", "cdn", "worker", "relay", "auto_cdn_ip", "old_xtls_direct", "sub_link_only")) | .domain')
domains=$(cat ../current.json | jq -r '.domains[] | select(.mode | IN("direct",   "relay", "old_xtls_direct", "sub_link_only")) | .domain')

for d in $domains; do
    get_cert $d &
done
wait

domains=$(cat ../current.json | jq -r '.domains[] | select(.mode | IN("fake")) | .domain')
for d in $domains; do
    get_self_signed_cert $d &
done
wait

for f in ../ssl/*.crt; do
    d=$(basename "$f" .crt)
    get_self_signed_cert $d &
done
wait
systemctl reload hiddify-haproxy
systemctl reload hiddify-singbox
# systemctl reload hiddify-xray