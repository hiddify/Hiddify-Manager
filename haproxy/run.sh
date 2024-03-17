# ln -sf $(pwd)/haproxy.cfg /etc/haproxy/haproxy.cfg

# REALITY_SERVER_NAMES_HAPROXY=$(echo "$REALITY_SERVER_NAMES" | sed 's/,/ || /g')
# sed -i "s|REALITY_SERVER_NAMES|server $REALITY_SERVER_NAMES_HAPROXY|g" haproxy.cfg

#
source ../common/utils.sh
domains=$(cat ../current.json | jq -r '.domains[] | select(.mode | IN("direct", "cdn", "worker", "relay", "auto_cdn_ip", "old_xtls_direct", "sub_link_only", "fake")) | .domain')

# we need at least one ssl certificate to be able to run haproxy
for d in $domains; do
    bash ../acme.sh/generate_self_signed_cert.sh $d
done

# systemctl reload hiddify-haproxy
systemctl restart hiddify-haproxy.service
systemctl start hiddify-haproxy
