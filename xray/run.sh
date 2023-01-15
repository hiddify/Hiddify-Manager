# mv /usr/local/etc/xray/config.json /usr/local/etc/xray/config.json.old
# ln -sf $(pwd)/xtls-config.json /usr/local/etc/xray/config.json
# ln -sf $(pwd)/xtls-sni-config.json /usr/local/etc/xray/config.json
#sed -i "s/^User=/#User=/g" /etc/systemd/system/xray.service

ln -sf $(pwd)/hiddify-xray.service /etc/systemd/system/hiddify-xray.service
systemctl enable hiddify-xray.service

MAIN_DOMAIN="$MAIN_DOMAIN;$SERVER_IP.sslip.io"
DOMAINS=${MAIN_DOMAIN//;/ }
USERS=${USER_SECRET//;/ }



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

if [[ "$BLOCK_IR_SITES" == "true" ]];then
        # sed -i 's|"tag": "forbidden_sites", "protocol": "blackhole"|"tag": "forbidden_sites", "protocol": "freedom"|g' configs/06_outbounds.json
		sed -i 's|"inboundTag": ["Experimental"],||g' configs/03_routing.jsons	
fi 


rm -rf /dev/shm/hiddify-xtls-main.sock
systemctl restart hiddify-xray.service



