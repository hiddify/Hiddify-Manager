# ln -sf $(pwd)/haproxy.cfg /etc/haproxy/haproxy.cfg

# REALITY_SERVER_NAMES_HAPROXY=$(echo "$REALITY_SERVER_NAMES" | sed 's/,/ || /g')
# sed -i "s|REALITY_SERVER_NAMES|server $REALITY_SERVER_NAMES_HAPROXY|g" haproxy.cfg

#
source ../common/utils.sh
set_domains_vars_from_hpanel

all_domains="$DOMAINS $FAKE_DOMAINS"
# we need at least one ssl certificate to be able to run haproxy
for d in $all_domains; do
    bash ../acme.sh/generate_self_signed_cert.sh $d
done

# systemctl reload hiddify-haproxy
systemctl restart hiddify-haproxy.service
systemctl start hiddify-haproxy
