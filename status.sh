#!/bin/bash
function main(){
	systemctl status --no-pager nginx hiddify-xray hiddify-sniproxy|cat

for s in **/*.service netdata nginx;do
	s=${s##*/}
	s=${s%%.*}
	printf "%-30s %-30s \n" $s $(systemctl is-active $s)
done



}
mkdir -p log/system/
main |& tee log/system/status.log
