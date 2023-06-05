#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

cd $( dirname -- "$0"; )

function main(){
	for s in **/*.service netdata nginx;do
		s=${s##*/}
		s=${s%%.*}
		printf "%-30s %-30s \n" $s $(systemctl restart $s)
	done

	bash status.sh
}

mkdir -p log/system/
main $@|& tee log/system/restart.log