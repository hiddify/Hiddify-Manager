#!/bin/bash
cd $( dirname -- "$0"; )
source /opt/hiddify-manager/scripts/common/utils.sh

function main(){
    activate_python_venv
    hiddify-panel-cli backup
}
main |& tee -a /opt/hiddify-manager/data/log/system/backup.log