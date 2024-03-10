#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

cd $( dirname -- "$0"; )
source ./common/utils.sh

function main() {
	before_stats=""
	after_stats=""

	# Restart services and get their status (except hiddify-panel)
    for s in other/**/*.service **/*.service wg-quick@warp mtproto-proxy.service mtproxy.service;do
        s=${s##*/}
        s=${s%%.*}
		if [ "$s" == "hiddify-panel" ]; then
			continue;
		fi
		if systemctl is-enabled $s >/dev/null 2>&1 ; then
			before_stats+=$(printf "%-30s %-30s %30s" $s $(get_pretty_service_status $s 2>&1) "\n")
			systemctl restart "$s"
			after_stats+=$(printf "%-30s %-30s %30s" $s $(get_pretty_service_status $s 2>&1) "\n")
		fi
    done
	
	# Restart hiddify-panel separately from others
	before_stats+=$(printf "%-30s %-30s %30s" hiddify-panel $(get_pretty_service_status hiddify-panel 2>&1) "\n")
	systemctl restart hiddify-panel &
	after_stats+=$(printf "%-30s %-30s %30s" hiddify-panel $(get_pretty_service_status hiddify-panel 2>&1) "\n")

	echo -e "\n----------------------------------------------------------------"
	warning "- Services Status Before Restart:"
	printf "$before_stats"
	echo "----------------------------------------------------------------"
	success "- Services Status After Restart:"
	printf "$after_stats"
	echo -e "----------------------------------------------------------------\n"
}
mkdir -p log/system/
main $@|& tee log/system/restart.log