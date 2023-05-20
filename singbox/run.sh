ln -sf $(pwd)/hiddify-singbox.service /etc/systemd/system/hiddify-singbox.service
systemctl enable hiddify-singbox.service

DOMAINS=${MAIN_DOMAIN//;/ }
USERS=${USER_SECRET//;/ }

for USER in $USERS; do
	GUID_USER="${USER:0:8}-${USER:8:4}-${USER:12:4}-${USER:16:4}-${USER:20:12}@hiddify.com"
	final=$final,\"$GUID_USER\"
done
final=${final:1}
sed -i "s|USERSLIST|$final|g" configs/01_api.json

# REALITY_SERVER_NAMES_XRAY=$(echo "$REALITY_SERVER_NAMES" | sed 's/,/\", \"/g; s/^/\"/; s/$/\"/')
REALITY_SHORT_IDS_XRAY=$(echo "$REALITY_SHORT_IDS" | sed 's/,/\", \"/g; s/^/\"/; s/$/\"/')
# sed -i "s|REALITY_SERVER_NAMES|$REALITY_SERVER_NAMES_XRAY|g" configs/05_inbounds_2001_reality_main.json
sed -i "s|REALITY_SHORT_IDS|$REALITY_SHORT_IDS_XRAY|g" configs/05_inbounds_2061_reality_main.json
sed -i "s|REALITY_SHORT_IDS|$REALITY_SHORT_IDS_XRAY|g" configs/05_inbounds_2071_realitygrpc_main.json
# sed -i "s|REALITY_FALLBACK_DOMAIN|$REALITY_FALLBACK_DOMAIN|g" configs/05_inbounds_2001_reality_main.json
sed -i "s|REALITY_PRIVATE_KEY|$REALITY_PRIVATE_KEY|g" configs/05_inbounds_2061_reality_main.json
sed -i "s|REALITY_PRIVATE_KEY|$REALITY_PRIVATE_KEY|g" configs/05_inbounds_2071_realitygrpc_main.json




rm configs/05_inbounds_2001_reality_*
find configs -name "05_inbounds_2061_reality_*.json" ! -name "05_inbounds_2061_reality_main.json" -type f -exec rm {} +
find configs -name "05_inbounds_2071_realitygrpc_*.json" ! -name "05_inbounds_2071_realitygrpc_main.json" -type f -exec rm {} +


REALITY_DOMAINS=${REALITY_MULTI//;/ }
i=1
for REALITY in $REALITY_DOMAINS;	do
  IFS=':' read -ra PARTS <<< "$REALITY"
  cp configs/05_inbounds_2061_reality_main.json configs/05_inbounds_2061_reality_$i.json
  
  FALLBACK_DOMAIN="${PARTS[0]}"
  #SERVER_NAMES="${PARTS[1]}"
#   SERVER_NAMES="${PARTS[1]//,/ }"  # Replace commas with spaces
  REALITY_SERVER_NAMES_XRAY=$(echo "${PARTS[1]}" | sed 's/,/\", \"/g; s/^/\"/; s/$/\"/')
  REALITY_SERVER_NAME=$(echo "${PARTS[1]}" | cut -d ',' -f 1)
  sed -i "s|REALITY_SERVER_NAME|$REALITY_SERVER_NAME|g" configs/05_inbounds_2061_reality_$i.json
  sed -i "s|REALITY_FALLBACK_DOMAIN|$FALLBACK_DOMAIN|g" configs/05_inbounds_2061_reality_$i.json
  sed -i "s|REALITY_SERVER_NAMES|$REALITY_SERVER_NAMES_XRAY|g" configs/05_inbounds_2061_reality_$i.json
  sed -i "s|2061|206$i|g" configs/05_inbounds_2061_reality_$i.json
  sed -i "s|realityin|realityin_$i|g" configs/05_inbounds_2061_reality_$i.json

  i=$((i+1))
done


REALITY_DOMAINS=${REALITY_MULTI_GRPC//;/ }
i=1
for REALITY in $REALITY_DOMAINS;	do
  IFS=':' read -ra PARTS <<< "$REALITY"
  cp configs/05_inbounds_2071_realitygrpc_main.json configs/05_inbounds_2071_realitygrpc_$i.json
  FALLBACK_DOMAIN="${PARTS[0]}"
  #SERVER_NAMES="${PARTS[1]}"
#   SERVER_NAMES="${PARTS[1]//,/ }"  # Replace commas with spaces
  REALITY_SERVER_NAMES_XRAY=$(echo "${PARTS[1]}" | sed 's/,/\", \"/g; s/^/\"/; s/$/\"/')
  REALITY_SERVER_NAME=$(echo "${PARTS[1]}" | cut -d ',' -f 1)
  sed -i "s|REALITY_SERVER_NAME|$REALITY_SERVER_NAME|g" configs/05_inbounds_2071_realitygrpc_$i.json
  sed -i "s|REALITY_FALLBACK_DOMAIN|$FALLBACK_DOMAIN|g" configs/05_inbounds_2071_realitygrpc_$i.json
  sed -i "s|REALITY_SERVER_NAMES|$REALITY_SERVER_NAMES_XRAY|g" configs/05_inbounds_2071_realitygrpc_$i.json
  sed -i "s|2071|207$i|g" configs/05_inbounds_2071_realitygrpc_$i.json
  sed -i "s|realityingrpc|realityingrpc_$i|g" configs/05_inbounds_2071_realitygrpc_$i.json
  i=$((i+1))
done
rm configs/05_inbounds_2061_reality_main.json
rm configs/05_inbounds_2071_realitygrpc_main.json




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

for CONFIG_FILE in $(find tests/ -name "*.json"); do
		for USER in $USERS; do
			GUID_USER="${USER:0:8}-${USER:8:4}-${USER:12:4}-${USER:16:4}-${USER:20:12}"
			sed -i "s|defaultuserguidsecret|$GUID_USER|g" $CONFIG_FILE
		done
sed -i "s|REALITY_FALLBACK_DOMAIN|$FALLBACK_DOMAIN|g" $CONFIG_FILE

sed -i "s|REALITY_PUBLIC_KEY|$REALITY_PUBLIC_KEY|g" $CONFIG_FILE
sed -i "s|REALITY_SHORT_ID||g" $CONFIG_FILE
done


# warp_conf=$(cat ../other/warp/singbox_warp_conf.json)


if [ -n "$dns_server" ];then
	sed -i "s|1.1.1.1|$dns_server|g"  configs/02_dns.json
fi

curl -s -x socks://127.0.0.1:3000 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query
if [ $WARP_MODE != 'disable' && "$?"  == "0" ];then
	# warp_conf=$(echo "$warp_conf" | tr '\n' ' ')
	# escaped_warp_conf=$(printf '%s\n' "$warp_conf" | sed -e 's/[\/&]/\\&/g')
	# sed -i "s|\"outbounds\": \[|\"outbounds\": [$escaped_warp_conf,|g"  configs/06_outbounds.json
	# sed -i "s|//hiddify_warp|$escaped_warp_conf,|g"  configs/06_outbounds.json
	if [ $WARP_MODE == 'all' ];then
		sed -i 's|"final": "freedom"|"final": "WARP"|g' configs/03_routing.json
	fi
	sed -i 's|"outbound": "forbidden_sites"|"outbound": "WARP"|g' configs/03_routing.json
else 
	sed -i 's|"outbound": "WARP"|"outbound": "freedom"|g' configs/03_routing.json

	if [[ "$BLOCK_IR_SITES" != "true" ]];then
        sed -i 's|"tag": "forbidden_sites", "type": "block"|"tag": "forbidden_sites", "type": "direct"|g' configs/06_outbounds.json
		# sed -i 's|"inboundTag": ["Experimental"],||g' configs/03_routing.json	
	fi 

fi



# sing-box check -C configs
echo "ignoring singbox test"
if  [[ $? == 0 ]];then
	#systemctl restart hiddify-singbox.service
    systemctl reload hiddify-singbox.service
	systemctl start hiddify-singbox.service
	systemctl status hiddify-singbox.service --no-pager
else
	echo "Error in singbox Config!!!! do not reload singbox service"
	sleep 3
	singbox check -C configs
	if  [[ $? == 0 ]];then
		systemctl reload hiddify-singbox.service
        systemctl start hiddify-singbox.service
        systemctl status hiddify-singbox.service --no-pager
	else
		echo "Error in singbox Config!!!! do not reload singbox service"
	fi
fi



