#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

cd /opt/hiddify-manager
source /opt/hiddify-manager/scripts/common/utils.sh
ACTION="${HIDDIFY_SYSTEMCTL_ACTION:-restart}"
LOG_NAME="restart"
case "$ACTION" in
start) LOG_NAME="run" ;;
stop) LOG_NAME="stop" ;;
esac
function restart_service() {
    local s=$1
    s=${s##*/}
    s=${s%%.*}
    if systemctl is-enabled $s >/dev/null 2>&1 ; then
        before_stat=$(get_pretty_service_status $s 2>&1)
        systemctl "$ACTION" $s &
        sleep 2
        for i in {1..10};do
            new_status=$(get_pretty_service_status $s 2>&1)
            if [ "$ACTION" = "stop" ]; then
                [[ "$new_status" != *active* ]] && break
            else
                [[ "$new_status" == *active* ]] && break
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
    for ss in services/**/*.service wg-quick@warp mtproto-proxy.service mtproxy.service mariadb;do
        case "$ss" in
            *hiddify-panel*|*hiddify-cli*)
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
mkdir -p /opt/hiddify-manager/data/log/system/
main $@|& tee /opt/hiddify-manager/data/log/system/${LOG_NAME}.log
