# ln -sf $(pwd)/haproxy.cfg /etc/haproxy/haproxy.cfg

# REALITY_SERVER_NAMES_HAPROXY=$(echo "$REALITY_SERVER_NAMES" | sed 's/,/ || /g')
# sed -i "s|REALITY_SERVER_NAMES|server $REALITY_SERVER_NAMES_HAPROXY|g" haproxy.cfg

#
source ../common/utils.sh
domains=$(cat ../current.json | jq -r '.domains[] | select(.mode | IN("direct", "cdn", "worker", "relay", "auto_cdn_ip", "old_xtls_direct", "sub_link_only", "fake")) | .domain')


# Loop over the .crt files
for f in ../ssl/*.crt; do
    # Get the basename without the .crt extension
    d=$(basename "$f" .crt)
    
    # Check if $d is not in the list of domains
    if [[ ! " ${domains[@]} " =~ " ${d} " ]]; then
        # If $d is not in domains, remove the file
        rm "../ssl/$d.crt"
        rm "../ssl/$d.crt.key"
    fi
done

# we need at least one ssl certificate to be able to run haproxy
for d in $domains; do
    bash ../acme.sh/generate_self_signed_cert.sh $d
done

# systemctl reload hiddify-haproxy
systemctl restart hiddify-haproxy.service
systemctl start hiddify-haproxy
