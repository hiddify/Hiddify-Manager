#!/bin/bash

# USER_SECRET=$1
# DOMAIN=$2
# IP=$(curl -Lso- https://api.ipify.org);
# echo $IP
# guid="${1:0:8}-${1:8:4}-${1:12:4}-${1:16:4}-${1:20:12}"
# cloudprovider=${4:-$DOMAIN}

if [[ "$ENABLE_SPEED_TEST" == "true" ]];then
	
else
	rm conf.d/speedtest.conf
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


systemctl restart hiddify-nginx
