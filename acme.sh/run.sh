domains=$(cat ../current.json | jq -r '.domains[] | select(.mode | IN("direct", "cdn", "worker", "relay", "auto_cdn_ip", "old_xtls_direct", "sub_link_only")) | .domain')

for d in $domains; do
	bash get_cert.sh $d
done

domains=$(cat ../current.json | jq -r '.domains[] | select(.mode | IN("fake")) | .domain')

for d in $domains; do
	bash generate_self_signed_cert.sh $d
done