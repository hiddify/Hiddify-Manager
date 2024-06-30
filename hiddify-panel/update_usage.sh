#!/bin/bash

cd $(dirname -- "$0")
source ../common/utils.sh

function main() {
    echo "trying to update usage"
    if [ -z $(pgrep -f 'hiddifypanel update-usage') ]; then
            hiddify-panel-cli "update-usage"
    fi
    
    rm ../log/update_usage.lock
}

if [[ -f ../log/update_usage.lock && $(($(date +%s) - $(cat ../log/update_usage.lock))) -lt 300 ]]; then
    echo "Another usage update is running.... Please wait until it finishes or wait 5 minutes or execute 'rm -f ../log/update_usage.lock'"
    exit 1
fi

echo "$(date +%s)" >../log/update_usage.lock
main |& tee -a ../log/system/update_usage.log
