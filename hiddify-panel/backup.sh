#!/bin/bash
cd $( dirname -- "$0"; )
source ../common/utils.sh

function main(){
    activate_python_venv
    hiddify-panel-cli backup
}
main |& tee -a ../log/system/backup.log