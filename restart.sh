#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

cd $( dirname -- "$0"; )
source ./common/utils.sh

function main() {
    echo -e "\n----------------------------------------------------------------"
    warning "$(printf "%-30s %-20s %s \n" "Name" "Old Status" "New Status")"
    
    # Restart services and get their status (except hiddify-panel)
    for s in other/**/*.service **/*.service wg-quick@warp mtproto-proxy.service mtproxy.service mariadb;do
        s=${s##*/}
        s=${s%%.*}
        if [ "$s" == "hiddify-panel" ]; then
            continue;
        fi
        if systemctl is-enabled $s >/dev/null 2>&1 ; then
            before_stat=$(get_pretty_service_status $s 2>&1)
            systemctl restart "$s" 2>/dev/null
            printf "%-30s %-20s ---> %+19s \n" $s $before_stat $(get_pretty_service_status $s 2>&1)
        fi
    done
    
    # Restart hiddify-panel separately from others
    before_stat=$(get_pretty_service_status hiddify-panel 2>&1)
    systemctl restart hiddify-panel &
    printf "%-30s %-20s ---> %+19s \n" hiddify-panel $before_stat $(get_pretty_service_status hiddify-panel 2>&1)
    
    echo -e "----------------------------------------------------------------\n"
}
mkdir -p log/system/
main $@|& tee log/system/restart.log
