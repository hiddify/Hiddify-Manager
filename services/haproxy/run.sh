# ln -sf $(pwd)/haproxy.cfg /etc/haproxy/haproxy.cfg

# REALITY_SERVER_NAMES_HAPROXY=$(echo "$REALITY_SERVER_NAMES" | sed 's/,/ || /g')
# sed -i "s|REALITY_SERVER_NAMES|server $REALITY_SERVER_NAMES_HAPROXY|g" haproxy.cfg

#
source /opt/hiddify-manager/scripts/common/utils.sh
systemctl daemon-reload

# systemctl reload hiddify-haproxy
systemctl stop hiddify-haproxy
systemctl start hiddify-haproxy
