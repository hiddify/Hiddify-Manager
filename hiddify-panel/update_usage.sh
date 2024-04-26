#!/bin/bash

cd $(dirname -- "$0")
source ../common/utils.sh

function main() {
    echo "trying to update usage"
    if [ -z $(pgrep -f 'hiddifypanel update-usage') ]; then
        if [ $(whoami) == 'hiddify-panel' ]; then
            activate_python_venv
            python -m hiddifypanel update-usage
        else
            hiddify-panel-run "python -m hiddifypanel update-usage"
            # doesn't load virtual env
            #su hiddify-panel -c "python -m hiddifypanel update-usage"
        fi
    fi
    
    rm ../log/update_usage.lock
}

if [[ -f ../log/update_usage.lock && $(($(date +%s) - $(cat ../log/update_usage.lock))) -lt 300 ]]; then
    echo "Another usage update is running.... Please wait until it finishes or wait 5 minutes or execute 'rm -f ../log/update_usage.lock'"
    exit 1
fi

echo "$(date +%s)" >../log/update_usage.lock
main |& tee -a ../log/system/update_usage.log
