ln -sf $(pwd)/haproxy.cfg /etc/haproxy/haproxy.cfg
if [[ "$SHADOWTLS_FAKEDOMAIN" == "" ]];then
sed -i "s|server shadowtls_decoy_http |server shadowtls_decoy_http no.com|g" haproxy.cfg
sed -i "s|server shadowtls_decoy |server shadowtls_decoy no.com|g" haproxy.cfg
fi

PORT_80=''
for PORT in ${HTTP_PORTS//,/ };	do 
  PORT_80="$PORT_80\n  bind *:$PORT"
done
sed -i "s|bind \*:80|$PORT_80|g" haproxy.cfg

PORT_443=''
for PORT in ${TLS_PORTS//,/ };	do 
  PORT_443='$PORT_443\n  bind *:$PORT'
done
sed -i "s|bind \*:443|$PORT_443|g" haproxy.cfg

 systemctl reload haproxy
 systemctl start haproxy