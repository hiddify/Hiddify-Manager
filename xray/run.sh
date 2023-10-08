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
sed -i "s|REALITY_SHORT_IDS|$REALITY_SHORT_IDS_XRAY|g" configs/05_inbounds_02_realityh2_main.json
# sed -i "s|REALITY_FALLBACK_DOMAIN|$REALITY_FALLBACK_DOMAIN|g" configs/05_inbounds_02_reality_main.json
sed -i "s|REALITY_PRIVATE_KEY|$REALITY_PRIVATE_KEY|g" configs/05_inbounds_02_reality_main.json
sed -i "s|REALITY_PRIVATE_KEY|$REALITY_PRIVATE_KEY|g" configs/05_inbounds_02_realitygrpc_main.json
sed -i "s|REALITY_PRIVATE_KEY|$REALITY_PRIVATE_KEY|g" configs/05_inbounds_02_realityh2_main.json

find configs -name "05_inbounds_02_reality_*.json" ! -name "05_inbounds_02_reality_main.json" -type f -exec rm {} +
find configs -name "05_inbounds_02_realitygrpc_*.json" ! -name "05_inbounds_02_realitygrpc_main.json" -type f -exec rm {} +

REALITY_DOMAINS=${REALITY_MULTI//;/ }
i=1
for REALITY in $REALITY_DOMAINS; do
	IFS=':' read -ra PARTS <<<"$REALITY"
	cp configs/05_inbounds_02_reality_main.json configs/05_inbounds_02_reality_$i.json
	cp configs/05_inbounds_02_realityh2_main.json configs/05_inbounds_02_realityh2_$i.json

	FALLBACK_DOMAIN="${PARTS[0]}"
	#SERVER_NAMES="${PARTS[1]}"
	#   SERVER_NAMES="${PARTS[1]//,/ }"  # Replace commas with spaces
	REALITY_SERVER_NAMES_XRAY=$(echo "${PARTS[1]}" | sed 's/,/\", \"/g; s/^/\"/; s/$/\"/')

	sed -i "s|REALITY_FALLBACK_DOMAIN|$FALLBACK_DOMAIN|g" configs/05_inbounds_02_reality_$i.json

	sed -i "s|REALITY_SERVER_NAMES|$REALITY_SERVER_NAMES_XRAY|g" configs/05_inbounds_02_reality_$i.json

	sed -i "s|realityin|realityin_$i|g" configs/05_inbounds_02_reality_$i.json

	#sed -i "s|abns@realityin|abns@realityin_$i|g" configs/05_inbounds_02_reality_$i.json

	sed -i "s|REALITY_FALLBACK_DOMAIN|$FALLBACK_DOMAIN|g" configs/05_inbounds_02_realityh2_$i.json
	sed -i "s|REALITY_SERVER_NAMES|$REALITY_SERVER_NAMES_XRAY|g" configs/05_inbounds_02_realityh2_$i.json
	sed -i "s|realityinh2|realityinh2_$i|g" configs/05_inbounds_02_realityh2_$i.json

	i=$((i + 1))
done

REALITY_DOMAINS_GRPC=${REALITY_MULTI_GRPC//;/ }
i=1
for REALITY in $REALITY_DOMAINS_GRPC; do
	IFS=':' read -ra PARTS <<<"$REALITY"
	cp configs/05_inbounds_02_realitygrpc_main.json configs/05_inbounds_02_realitygrpc_$i.json

	FALLBACK_DOMAIN="${PARTS[0]}"
	#SERVER_NAMES="${PARTS[1]}"
	#   SERVER_NAMES="${PARTS[1]//,/ }"  # Replace commas with spaces
	REALITY_SERVER_NAMES_XRAY=$(echo "${PARTS[1]}" | sed 's/,/\", \"/g; s/^/\"/; s/$/\"/')
	sed -i "s|REALITY_FALLBACK_DOMAIN|$FALLBACK_DOMAIN|g" configs/05_inbounds_02_realitygrpc_$i.json
	sed -i "s|REALITY_SERVER_NAMES|$REALITY_SERVER_NAMES_XRAY|g" configs/05_inbounds_02_realitygrpc_$i.json
	sed -i "s|realityingrpc|realityingrpc_$i|g" configs/05_inbounds_02_realitygrpc_$i.json
	i=$((i + 1))
done

rm configs/05_inbounds_02_reality_main.json
rm configs/05_inbounds_02_realityh2_main.json
rm configs/05_inbounds_02_realitygrpc_main.json

local_ips=$(ip -o -4 addr show | awk '{print $4}' | cut -d/ -f1 | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$/\n/')

sed -i "s|//local_ips|,$local_ips|g" configs/03_routing.json

curl -s -x socks://127.0.0.1:3000 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query

if [ "$MODE" != "apply_users" ]; then

	# xray run -test -confdir configs
	echo "ignoring xray test"
	if [[ $? == 0 ]]; then
		systemctl restart hiddify-xray.service
		systemctl start hiddify-xray.service
		systemctl status hiddify-xray.service --no-pager
	else
		echo "Error in Xray Config!!!! do not reload xray service"
		sleep 60
		xray run -test -confdir configs
		if [[ $? == 0 ]]; then
			systemctl restart hiddify-xray.service
			systemctl start hiddify-xray.service
			systemctl status hiddify-xray.service --no-pager
		else
			echo "Error in Xray Config!!!! do not reload xray service"
			sleep 60
		fi
	fi

fi
