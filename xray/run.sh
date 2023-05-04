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


REALITY_SERVER_NAMES_XRAY=$(echo "$REALITY_SERVER_NAMES" | sed 's/,/\", \"/g; s/^/\"/; s/$/\"/')
REALITY_SHORT_IDS_XRAY=$(echo "$REALITY_SHORT_IDS" | sed 's/,/\", \"/g; s/^/\"/; s/$/\"/')
sed -i "s|REALITY_SERVER_NAMES|$REALITY_SERVER_NAMES_XRAY|g" configs/05_inbounds_02_reality_main.json
sed -i "s|REALITY_SHORT_IDS|$REALITY_SHORT_IDS_XRAY|g" configs/05_inbounds_02_reality_main.json
sed -i "s|REALITY_FALLBACK_DOMAIN|$REALITY_FALLBACK_DOMAIN|g" configs/05_inbounds_02_reality_main.json
sed -i "s|REALITY_PRIVATE_KEY|$REALITY_PRIVATE_KEY|g" configs/05_inbounds_02_reality_main.json


#adding certs for all domains
final=""
TEMPLATE_LINE='{"ocspStapling": 3600, "certificateFile": "ssl.crt", "keyFile": "ssl.key"}'
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

if [[ "$BLOCK_IR_SITES" != "true" ]];then
        sed -i 's|"tag": "forbidden_sites", "protocol": "blackhole"|"tag": "forbidden_sites", "protocol": "freedom"|g' configs/06_outbounds.json
		# sed -i 's|"inboundTag": ["Experimental"],||g' configs/03_routing.json
		
fi 

if [[ "$HTTP_PORTS" != "" ]];then
	sed -i 's|"port":"80"|"port":"80,'$HTTP_PORTS'"|g' configs/05_inbounds_02_http_main.json
fi




rm configs/warp_conf.json

warp_conf=$(cat ../other/warp/xray/warp_conf.json)

if [ -n "warp_conf" ];then
	warp_conf=$(echo "$warp_conf" | tr '\n' ' ')
	escaped_warp_conf=$(printf '%s\n' "$warp_conf" | sed -e 's/[\/&]/\\&/g')
	sed -i "s|\"outbounds\": \[|\"outbounds\": [$escaped_warp_conf,|g"  06_outbounds.json
	
	sed -i 's|"outboundTag": "forbidden_sites"|"outboundTag": "WARP-free"|g' configs/03_routing.json
	sed -i 's|"outboundTag": "WARP"|"outboundTag": "WARP-free"|g' configs/03_routing.json
else 
	sed -i 's|"outboundTag": "WARP"|"outboundTag": "freedom"|g' configs/03_routing.json
fi



xray run -test -confdir configs
# echo "ignoring xray test"
if  [[ $? == 0 ]];then
	systemctl restart hiddify-xray.service
	systemctl start hiddify-xray.service
	systemctl status hiddify-xray.service
else
	echo "Error in Xray Config!!!! do not reload xray service"
	sleep 60
	xray run -test -confdir configs
	if  [[ $? == 0 ]];then
		systemctl restart hiddify-xray.service
		systemctl start hiddify-xray.service
		systemctl status hiddify-xray.service
	else
		echo "Error in Xray Config!!!! do not reload xray service"
		sleep 60
	fi
fi



