#!/bin/bash
function main(){
XRAY_NEW_CONFIG_ERROR=0
xray run -test -confdir xray/configs > /dev/null 2>&1
XRAY_NEW_CONFIG_OK=$?

	systemctl status --no-pager hiddify-nginx hiddify-xray haproxy|cat

warp_conf=$(cat other/warp/xray_warp_conf.json)

if [ -n "$warp_conf" ];then
	(cd other/warp&& wgcf update)
	echo "Your IP for custom WARP:"
	curl -x socks://127.0.0.1:1234 www.ipinfo.io

	echo "Your Global IP"
	curl -x socks://127.0.0.1:1234 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query
fi


for s in other/**/*.service **/*.service haproxy ;do
	s=${s##*/}
	s=${s%%.*}
	printf "%-30s %-30s \n" $s $(systemctl is-active $s)
done


# echo "ignoring xray test"


if [ "$XRAY_NEW_CONFIG_ERROR" != "0" ];then
	xray run -test -confdir xray/configs 
	echo "There is a big error in xray configuration."
fi
}
mkdir -p log/system/
main |& tee log/system/status.log
