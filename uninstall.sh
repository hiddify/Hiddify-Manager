#!/bin/bash
cd $(dirname -- "$0")
function main(){
    for s in netdata other/**/*.service **/*.service nginx;do
        s=${s##*/}
        s=${s%%.*}
        systemctl kill $s
        systemctl disable $s
    done
    rm -rf /etc/cron.d/hiddify*
    service cron reload
    if [[ "$1" == "purge" ]];then
        rm -rf hiddify-panel
        apt purge -y nginx gunicorn mariadb-* #python3-pip python3
        rm -rf *
        echo "We have completely removed hiddify panel"
    fi
}

mkdir -p log/system/
main $@|& tee log/system/uninstall.log
