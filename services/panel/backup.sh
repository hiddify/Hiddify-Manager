#!/bin/bash
cd $( dirname -- "$0"; )
source /opt/hiddify-manager/scripts/common/utils.sh

function main(){
    activate_python_venv
    # Runs before install.sh during updates, so it cannot rely on the installer having fixed ownership.
    ensure_panel_backup_dir
    hiddify-panel-cli backup
}
main |& tee -a /opt/hiddify-manager/data/log/system/backup.log