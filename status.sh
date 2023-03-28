#!/bin/bash
function main(){
	systemctl status --no-pager hiddify-nginx hiddify-xray haproxy|cat

for s in netdata other/**/*.service **/*.service haproxy;do
	s=${s##*/}
	s=${s%%.*}
	printf "%-30s %-30s \n" $s $(systemctl is-active $s)
done

# xray run -test -confdir xray/configs > /dev/null 2>&1
echo "ignoring xray test"
if  [[ $? != 0 ]];then

	xray run -test -confdir xray/configs 

	echo "There is a big error in xray configuration."
fi

}
mkdir -p log/system/
main |& tee log/system/status.log
