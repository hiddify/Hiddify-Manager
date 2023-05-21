# ln -sf $(pwd)/haproxy.cfg /etc/haproxy/haproxy.cfg
if [[ "$SHADOWTLS_FAKEDOMAIN" == "" ]];then
sed -i "s|server shadowtls_decoy_http |server shadowtls_decoy_http no.com|g" common.cfg
sed -i "s|server shadowtls_decoy |server shadowtls_decoy no.com|g" common.cfg
fi

# REALITY_SERVER_NAMES_HAPROXY=$(echo "$REALITY_SERVER_NAMES" | sed 's/,/ || /g')
# sed -i "s|REALITY_SERVER_NAMES|server $REALITY_SERVER_NAMES_HAPROXY|g" haproxy.cfg

REALITY_DOMAINS=${REALITY_MULTI//;/ }
REALITY_DOMAINS_GRPC=${REALITY_MULTI_GRPC//;/ }

XRAY_DOMAINS_MULTI=$(echo "$FORCE_XRAY_DOMAINS_MULTI" | sed 's/,/ || /g')


sed -i "s|FORCE_XRAY_DOMAINS|$XRAY_DOMAINS_MULTI|g" common.cfg
i=1
for REALITY in $REALITY_DOMAINS;	do
  IFS=':' read -ra PARTS <<< "$REALITY"
  
  FALLBACK_DOMAIN="${PARTS[0]}"
  #SERVER_NAMES="${PARTS[1]}"
  SERVER_NAMES="${PARTS[1]//,/ }"  # Replace commas with spaces
  
  sed -i "s|#reality_configs|\
    #reality_configs\n\
    acl reality_domains_$i req.ssl_sni -i $SERVER_NAMES\n\
    use_backend reality_$i if reality_domains_$i|g" common.cfg


  sed -i "s|#reality_http_configs|\
    #reality_http_configs\n\
    acl reality_domains_$i hdr(host) -i $SERVER_NAMES\n\
    use_backend reality_http_$i if reality_domains_$i|g" common.cfg


  cat >> common.cfg << EOF
backend reality_http_$i
    mode http
    server reality_$i $FALLBACK_DOMAIN:80 
    
EOF

  cat >> xray.cfg << EOF
backend reality_$i
    mode tcp
    server xray abns@realityin_$i send-proxy-v2

EOF

  cat >> singbox.cfg << EOF
backend reality_$i
    mode tcp
    server singbox 127.0.0.1:206$i send-proxy-v2

EOF

  i=$((i+1))
done





i=1
for REALITY in $REALITY_DOMAINS_GRPC;	do
  IFS=':' read -ra PARTS <<< "$REALITY"
  
  FALLBACK_DOMAIN="${PARTS[0]}"
  #SERVER_NAMES="${PARTS[1]}"
  SERVER_NAMES="${PARTS[1]//,/ }"  # Replace commas with spaces
  
  sed -i "s|#reality_configs|\
    #reality_configs\n\
    acl reality_domains_grpc_$i req.ssl_sni -i $SERVER_NAMES\n\
    use_backend reality_grpc_$i if reality_domains_grpc_$i|g" common.cfg

  sed -i "s|#reality_http_configs|\
    #reality_http_configs\n\
    acl reality_domains_grpc_$i hdr(host) -i $SERVER_NAMES\n\
    use_backend reality_grpc_http_$i if reality_domains_grpc_$i|g" common.cfg


  cat >> common.cfg << EOF
backend reality_grpc_http_$i
    mode http
    server reality_$i $FALLBACK_DOMAIN:80 
EOF

  cat >> xray.cfg << EOF
backend reality_grpc_$i
    mode tcp
    server xray abns@realityingrpc_$i send-proxy-v2
EOF

  cat >> singbox.cfg << EOF
backend reality_grpc_$i
    mode tcp
    server singbox 127.0.0.1:207$i send-proxy-v2
EOF

  i=$((i+1))
done




if [ "$core_type" == "xray" ];then
  rm singbox.cfg
elif [ "$core_type" == "singbox" ];then
  rm xray.cfg
fi


PORT_80=''
for PORT in ${HTTP_PORTS//,/ };	do 
  PORT_80="$PORT_80\n  bind *:$PORT,:::$PORT v4v6"
done
# sed -i "s|bind \*:80|$PORT_80|g" common.cfg
sed -i "s|bind :80,:::80 v4v6|$PORT_80|g" common.cfg
PORT_443='bind :443,:::443 v4v6'
for PORT in ${TLS_PORTS//,/ };	do 
  PORT_443="$PORT_443\n  bind :$PORT,:::$PORT v4v6"
done
sed -i "s|bind :443,:::443 v4v6|$PORT_443|g" common.cfg


 systemctl reload hiddify-haproxy
 systemctl start hiddify-haproxy
