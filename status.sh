#!/bin/bash
function main(){
for s in **/*.service v2ray netdata nginx xray;do
	s=${s##*/}
	s=${s%%.*}
	printf "%-30s %-30s \n" $s $(systemctl is-active $s)
done

}
mkdir -p log/system/
main |& tee log/system/status.log