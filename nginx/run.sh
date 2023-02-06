#!/bin/bash

# USER_SECRET=$1
# DOMAIN=$2
# IP=$(curl -Lso- https://api.ipify.org);
# echo $IP
# guid="${1:0:8}-${1:8:4}-${1:12:4}-${1:16:4}-${1:20:12}"
# cloudprovider=${4:-$DOMAIN}

if [[ "$ENABLE_SPEED_TEST" == "true" ]];then
	ln -sf  $(pwd)/speedtest.conf /etc/nginx/conf.d/speedtest.conf
else
	rm /etc/nginx/conf.d/speedtest.conf
fi

if [[ "$FIRST_SETUP" == "true" ]];then
	
	TEMP_LINK_VALID_TIME="$(date '+%Y-%m-%dT%H')"
	nextH="$(printf '%02d' $(($(date '+%H') +1)))"
	if [[ "$nextH" != "" ]];then
		TEMP_LINK_VALID_TIME=$(date "+%Y-%m-%dT(%H\|$nextH)")
	fi
	sed -i "s|TEMP_LINK_VALID_TIME|$TEMP_LINK_VALID_TIME|g" def-link.conf
fi
# if [[ "$ENABLE_MONITORING" == "false" ]];then
#         sed -i "s|access_log /opt/GITHUB_REPOSITORY/log/nginx.log proxy;|access_log off;|g" $out_file
# fi

systemctl stop nginx
pkill -9 nginx




# certbot certonly  --webroot -w $(pwd)/certbot --register-unsafely-without-email -d $MAIN_DOMAIN --non-interactive --agree-tos  --logs-dir $(pwd)/../log/system/certbot.log
 systemctl restart nginx
