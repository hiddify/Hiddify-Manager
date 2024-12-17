#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

cd $( dirname -- "$0"; )
source ./common/utils.sh
function restart_service() {
    local s=$1
    s=${s##*/}
    s=${s%%.*}
    if systemctl is-enabled $s >/dev/null 2>&1 ; then
        before_stat=$(get_pretty_service_status $s 2>&1)
        systemctl restart $s &
        sleep 2
        for i in {1..10};do
            new_status=$(get_pretty_service_status $s 2>&1)
            if [[ "$new_status" == *active* ]]; then
                break
            fi
            sleep 1
        done
        printf "%-30s %-20s ---> %+19s \n" $s $before_stat  $new_status
    fi
}
function main() {
    echo -e "\n----------------------------------------------------------------"
    warning "$(printf "%-30s %-20s %s \n" "Name" "Old Status" "New Status")"
    
    # Restart services and get their status (except hiddify-panel)
    for ss in other/**/*.service **/*.service wg-quick@warp mtproto-proxy.service mtproxy.service mariadb;do
        case "$ss" in
            hiddify-panel*|other/hiddify-cli*)
                continue
                ;;
            wg-quick@warp)
                [ "$(hconfig warp_mode)" == "disable" ] && continue
                ;;
        esac
        restart_service $ss &
    done
    wait
    # Restart hiddify-panel separately from others
    for ss in hiddify-panel hiddify-panel-background-tasks;do
        restart_service $ss &
    done
    wait

    for ss in hiddify-cli;do
        restart_service $ss &
    done
    wait
    echo -e "----------------------------------------------------------------\n"
}
mkdir -p log/system/
main $@|& tee log/system/restart.log
