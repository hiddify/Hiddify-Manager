#!/bin/bash
cd $( dirname -- "$0"; )
source ./common/utils.sh

function main(){
    # XRAY_NEW_CONFIG_ERROR=0
    # xray run -test -confdir xray/configs > /dev/null 2>&1
    # XRAY_NEW_CONFIG_ERROR=$?
    
    
    # SINGBOX_NEW_CONFIG_ERROR=0
    # xray run -test -confdir xray/configs > /dev/null 2>&1
    # SINGBOX_NEW_CONFIG_ERROR=$?
    
    
    # systemctl status --no-pager hiddify-nginx hiddify-xray hiddify-singbox hiddify-haproxy|cat
    
    if [[ $(hconfig "warp_mode") != "disable" ]];then
        echo -e "\n----------------------------------------------------------------"
        bash other/warp/status.sh
    fi
    
    echo "----------------------------------------------------------------"
    warning "- Global IP:"
    proxy_port=1234 # xray local socks5 port
    if [[ $(hconfig "core_type") == "singbox" ]];then
        proxy_port=2000 # singbox local socks5 port
    fi
    curl -s -x socks://127.0.0.1:$proxy_port --connect-timeout 1 http://ip-api.com?fields=country,city,org,query | sed 's|^|  |; /[{}]/d'
    echo "----------------------------------------------------------------"
    
    warning "- Services Status:"
    
    for s in other/**/*.service **/*.service wg-quick@warp mtproto-proxy.service mtproxy.service;do
        (
        s=${s##*/}
        s=${s%%.*}
        if [[ $s == "wg-quick@warp" ]] && [[ $(hconfig "warp_mode") == "disable" ]]; then
            return
        fi
        if systemctl is-enabled $s >/dev/null 2>&1 ; then
            status=$(get_pretty_service_status $s 2>&1)
            printf "    %-50s %+19s \n" "$s" "$status"
        fi
        )&
    done
    wait
    echo "----------------------------------------------------------------"
    
    # echo "ignoring xray test"
    
    
    # if [ "$XRAY_NEW_CONFIG_ERROR" != "0" ];then
    # 	xray run -test -confdir xray/configs
    # 	echo "There is a big error in xray configuration."
    # fi
    
    # if [ "$SINGBOX_NEW_CONFIG_ERROR" != "0" ];then
    # 	sing-box check -C singbox/configs
    # 	echo "There is a big error in xray configuration."
    # fi
}

mkdir -p log/system/
main |& tee log/system/status.log
