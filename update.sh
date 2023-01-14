#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

cd $( dirname -- "$0"; )

function main(){
    git branch
    changed=0
    git pull --dry-run 2>&1 | grep -q -v 'Already up-to-date.' && changed=1


    if [[ "$changed" == "1" ]];then
        echo "Updating system"
        git pull
        bash install.sh
    else 
        echo "No update is needed"
    fi
}

mkdir -p log/system/
main |& tee log/system/update.log