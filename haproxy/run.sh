ln -sf $(pwd)/haproxy.cfg /etc/haproxy/haproxy.cfg
if [[ "$SHADOWTLS_FAKEDOMAIN" == "" ]];then
sed -i "s|server shadowtls_decoy_http |server shadowtls_decoy_http no.com|g" haproxy.cfg
sed -i "s|server shadowtls_decoy |server shadowtls_decoy no.com|g" haproxy.cfg
fi
 systemctl reload haproxy
 systemctl start haproxy