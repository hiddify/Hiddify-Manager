#!/bin/bash

cd $(dirname -- "$0")
source /opt/hiddify-manager/scripts/common/utils.sh
NAME="update_usage"
function main() {
    echo "trying to update usage"
    
    
    hiddify-http-api admin/update_user_usage/
    if [ "$?" != 0 ] && [ -z $(pgrep -f 'hiddifypanel update-usage') ]; then
        hiddify-panel-cli "update-usage"
    fi
    

}

set_lock $NAME
main |& tee -a /opt/hiddify-manager/data/log/system/update_usage.log
remove_lock $NAME