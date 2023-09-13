#!/bin/bash

if [[ "$ENABLE_SPEED_TEST" != "true" ]]; then
	rm conf.d/speedtest.conf
fi
echo "" >parts/short-link.conf

if [[ "$FIRST_SETUP" == "true" ]]; then

	TEMP_LINK_VALID_TIME="$(date '+%Y-%m-%dT%H')"
	nextH="$(printf '%02d' $(($(date '+%H') + 1)))"
	if [[ "$nextH" != "" ]]; then
		TEMP_LINK_VALID_TIME=$(date "+%Y-%m-%dT(%H\|$nextH)")
	fi
	sed -i "s|TEMP_LINK_VALID_TIME|$TEMP_LINK_VALID_TIME|g" parts/def-link.conf
fi

systemctl reload hiddify-nginx
systemctl start hiddify-nginx
