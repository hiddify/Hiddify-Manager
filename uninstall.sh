#!/bin/bash
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
        cd .. && rm -rf hiddify-panel
        apt remove -y nginx gunicorn python3-pip python3
        echo "We have completely removed hiddify panel"
    fi
}

mkdir -p log/system/
main $@|& tee log/system/uninstall.log
