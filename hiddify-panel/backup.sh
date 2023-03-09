#!/bin/bash

cd $( dirname -- "$0"; )
function main(){
    python3 -m hiddifypanel backup
}
main |& tee -a ../log/system/backup.log