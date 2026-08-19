#!/bin/bash
cd /opt/hiddify-manager
function main(){
    for s in netdata services/**/*.service nginx;do
        s=${s##*/}
        s=${s%%.*}
        systemctl kill $s
        systemctl disable $s
    done
    rm -rf /etc/cron.d/hiddify*
    rm -f /usr/bin/hiddify /etc/bash_completion.d/hiddify /etc/profile.d/hiddify.sh
    service cron reload
    if [[ "$1" == "purge" ]];then
        rm -rf services/hiddify-panel
        apt purge -y nginx gunicorn mariadb-* #python3-pip python3
        rm -rf *
        echo "We have completely removed hiddify panel"
    fi
}

mkdir -p /opt/hiddify-manager/data/log/system/
main $@|& tee /opt/hiddify-manager/data/log/system/uninstall.log
