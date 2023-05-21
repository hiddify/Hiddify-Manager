# mv /usr/local/etc/xray/config.json /usr/local/etc/xray/config.json.old
# ln -sf $(pwd)/xtls-config.json /usr/local/etc/xray/config.json
# ln -sf $(pwd)/xtls-sni-config.json /usr/local/etc/xray/config.json
#sed -i "s/^User=/#User=/g" /etc/systemd/system/xray.service
mkdir -p run
ln -sf $(pwd)/hiddify-xray.service /etc/systemd/system/hiddify-xray.service
systemctl enable hiddify-xray.service

# MAIN_DOMAIN="$MAIN_DOMAIN;$SERVER_IP.sslip.io"
DOMAINS=${MAIN_DOMAIN//;/ }
USERS=${USER_SECRET//;/ }



REALITY_SHORT_IDS_XRAY=$(echo "$REALITY_SHORT_IDS" | sed 's/,/\", \"/g; s/^/\"/; s/$/\"/')

sed -i "s|REALITY_SHORT_IDS|$REALITY_SHORT_IDS_XRAY|g" configs/05_inbounds_02_reality_main.json
sed -i "s|REALITY_SHORT_IDS|$REALITY_SHORT_IDS_XRAY|g" configs/05_inbounds_02_realitygrpc_main.json
# sed -i "s|REALITY_FALLBACK_DOMAIN|$REALITY_FALLBACK_DOMAIN|g" configs/05_inbounds_02_reality_main.json
sed -i "s|REALITY_PRIVATE_KEY|$REALITY_PRIVATE_KEY|g" configs/05_inbounds_02_reality_main.json
sed -i "s|REALITY_PRIVATE_KEY|$REALITY_PRIVATE_KEY|g" configs/05_inbounds_02_realitygrpc_main.json



find configs -name "05_inbounds_02_reality_*.json" ! -name "05_inbounds_02_reality_main.json" -type f -exec rm {} +
find configs -name "05_inbounds_02_realitygrpc_*.json" ! -name "05_inbounds_02_realitygrpc_main.json" -type f -exec rm {} +

REALITY_DOMAINS=${REALITY_MULTI//;/ }
i=1
for REALITY in $REALITY_DOMAINS;	do
  IFS=':' read -ra PARTS <<< "$REALITY"
  cp configs/05_inbounds_02_reality_main.json configs/05_inbounds_02_reality_$i.json
  

  FALLBACK_DOMAIN="${PARTS[0]}"
  #SERVER_NAMES="${PARTS[1]}"
#   SERVER_NAMES="${PARTS[1]//,/ }"  # Replace commas with spaces
  REALITY_SERVER_NAMES_XRAY=$(echo "${PARTS[1]}" | sed 's/,/\", \"/g; s/^/\"/; s/$/\"/')
  
  sed -i "s|REALITY_FALLBACK_DOMAIN|$FALLBACK_DOMAIN|g" configs/05_inbounds_02_reality_$i.json
  
  sed -i "s|REALITY_SERVER_NAMES|$REALITY_SERVER_NAMES_XRAY|g" configs/05_inbounds_02_reality_$i.json  
  
  sed -i "s|realityin|realityin_$i|g" configs/05_inbounds_02_reality_$i.json
  
  #sed -i "s|abns@realityin|abns@realityin_$i|g" configs/05_inbounds_02_reality_$i.json  
  
  

  i=$((i+1))
done


REALITY_DOMAINS_GRPC=${REALITY_MULTI_GRPC//;/ }
i=1
for REALITY in $REALITY_DOMAINS_GRPC;	do
  IFS=':' read -ra PARTS <<< "$REALITY"
  cp configs/05_inbounds_02_realitygrpc_main.json configs/05_inbounds_02_realitygrpc_$i.json

  FALLBACK_DOMAIN="${PARTS[0]}"
  #SERVER_NAMES="${PARTS[1]}"
#   SERVER_NAMES="${PARTS[1]//,/ }"  # Replace commas with spaces
  REALITY_SERVER_NAMES_XRAY=$(echo "${PARTS[1]}" | sed 's/,/\", \"/g; s/^/\"/; s/$/\"/')
  sed -i "s|REALITY_FALLBACK_DOMAIN|$FALLBACK_DOMAIN|g" configs/05_inbounds_02_realitygrpc_$i.json
  sed -i "s|REALITY_SERVER_NAMES|$REALITY_SERVER_NAMES_XRAY|g" configs/05_inbounds_02_realitygrpc_$i.json  
  sed -i "s|realityingrpc|realityingrpc_$i|g" configs/05_inbounds_02_realitygrpc_$i.json
  i=$((i+1))
done
rm configs/05_inbounds_02_reality_main.json
rm configs/05_inbounds_02_realitygrpc_main.json






#adding certs for all domains
final=""
TEMPLATE_LINE='{"ocspStapling": 3600, "certificateFile": "ssl.crt", "keyFile": "ssl.crt.key"}'
for DOMAIN in $DOMAINS;do
	echo $DOMAIN
	NEW_LINE=${TEMPLATE_LINE//ssl/"/opt/$GITHUB_REPOSITORY/ssl/$DOMAIN"}	
	final=$final,$NEW_LINE
done
final=${final:1}
echo $final
sed -i "s|$TEMPLATE_LINE|$final|g" configs/05_inbounds_02_xtls_main.json
sed -i "s|$TEMPLATE_LINE|$final|g" configs/05_inbounds_02_decoy.json
sed -i "s|$TEMPLATE_LINE|$final|g" configs/05_inbounds_02_quic_main.json

for CONFIG_FILE in $(find configs/ -name "*.json"); do
	grep $CONFIG_FILE -e defaultuserguidsecret| while read -r line ; do
		# echo "Processing $line"
		final=""
		for USER in $USERS; do
			GUID_USER="${USER:0:8}-${USER:8:4}-${USER:12:4}-${USER:16:4}-${USER:20:12}"
			final=$final,${line//defaultuserguidsecret/"$GUID_USER"}
		done
		# your code goes here
		final=${final:1}
		sed -i "s|$line|$final|g" $CONFIG_FILE
	done

done


if [[ "$ALLOW_ALL_SNI_TO_USE_PROXY" == "true" ]];then
        sed -i 's|"redirect": "127.0.0.1:445"|"redirect": "127.0.0.1:400"|g' configs/05_inbounds_02_sni_proxy.json
fi


if [[ "$HTTP_PORTS" != "" ]];then
	sed -i 's|"port":"80"|"port":"80,'$HTTP_PORTS'"|g' configs/05_inbounds_02_http_main.json
fi





if [ -n "$dns_server" ];then
	sed -i "s|1.1.1.1|$dns_server|g"  configs/06_outbounds.json
fi

curl -s -x socks://127.0.0.1:3000 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query
if [ $WARP_MODE != 'disable' && "$?"  == "0" ];then
	# warp_conf=$(echo "$warp_conf" | tr '\n' ' ')
	# escaped_warp_conf=$(printf '%s\n' "$warp_conf" | sed -e 's/[\/&]/\\&/g')
	# sed -i "s|\"outbounds\": \[|\"outbounds\": [$escaped_warp_conf,|g"  configs/06_outbounds.json
	# sed -i "s|//hiddify_warp|$escaped_warp_conf,|g"  configs/06_outbounds.json

	if [ $WARP_MODE == 'all' ];then
		sed -i 's|"outboundTag": "freedom"|"outboundTag": "WARP"|g' configs/03_routing.json
	fi
	
	sed -i 's|"outboundTag": "forbidden_sites"|"outboundTag": "WARP"|g' configs/03_routing.json
else 
	sed -i 's|"outboundTag": "WARP"|"outboundTag": "freedom"|g' configs/03_routing.json

	if [[ "$BLOCK_IR_SITES" != "true" ]];then
        sed -i 's|"tag": "forbidden_sites", "protocol": "blackhole"|"tag": "forbidden_sites", "protocol": "freedom"|g' configs/06_outbounds.json
		# sed -i 's|"inboundTag": ["Experimental"],||g' configs/03_routing.json	
	fi 

fi



# xray run -test -confdir configs
echo "ignoring xray test"
if  [[ $? == 0 ]];then
	systemctl restart hiddify-xray.service
	systemctl start hiddify-xray.service
	systemctl status hiddify-xray.service --no-pager
else
	echo "Error in Xray Config!!!! do not reload xray service"
	sleep 60
	xray run -test -confdir configs
	if  [[ $? == 0 ]];then
		systemctl restart hiddify-xray.service
		systemctl start hiddify-xray.service
		systemctl status hiddify-xray.service --no-pager
	else
		echo "Error in Xray Config!!!! do not reload xray service"
		sleep 60
	fi
fi



