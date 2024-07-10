#!/bin/bash

cd $(dirname -- "$0")
source ../common/utils.sh
NAME="update_usage"
function main() {
    echo "trying to update usage"
    
    
    hiddify-http-api admin/update_user_usage/
    if [ "$?" != 0 ] && [ -z $(pgrep -f 'hiddifypanel update-usage') ]; then
        hiddify-panel-cli "update-usage"
    fi
    

}

set_lock $NAME
main |& tee -a ../log/system/update_usage.log
remove_lock $NAME