#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

cd $( dirname -- "$0"; )/

changed=0
git pull --dry-run 2>&1 | grep -q -v 'Already up-to-date.' && changed=1


if [[ "$changed" == "1" ]];then
    git pull
    bash install.sh
fi