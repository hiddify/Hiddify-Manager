# ln -sf $(pwd)/haproxy.cfg /etc/haproxy/haproxy.cfg

# REALITY_SERVER_NAMES_HAPROXY=$(echo "$REALITY_SERVER_NAMES" | sed 's/,/ || /g')
# sed -i "s|REALITY_SERVER_NAMES|server $REALITY_SERVER_NAMES_HAPROXY|g" haproxy.cfg

#
source ../common/utils.sh

chmod 600 *.cfg*
# systemctl reload hiddify-haproxy
systemctl stop hiddify-haproxy
systemctl start hiddify-haproxy
