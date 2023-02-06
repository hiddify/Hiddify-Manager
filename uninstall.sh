#!/bin/bash
function main(){

for s in netdata other/**/*.service **/*.service nginx;do
	s=${s##*/}
	s=${s%%.*}
	# printf "%-30s %-30s \n" $s $(systemctl is-active $s)
        systemctl kill $s
        systemctl disable $s
        
done



}
mkdir -p log/system/
main |& tee log/system/uninstall.log
