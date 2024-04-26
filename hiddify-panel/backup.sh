#!/bin/bash
cd $( dirname -- "$0"; )
source ../common/utils.sh

function main(){
    activate_python_venv
    python3 -m hiddifypanel backup
}
main |& tee -a ../log/system/backup.log