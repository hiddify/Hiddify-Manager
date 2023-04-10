#!/bin/bash

cd $( dirname -- "$0"; )
function main(){
    echp "trying to update usage"
    pgrep -f 'update-usage' || python3 -m hiddifypanel update-usage
}
main |& tee -a ../log/system/update_usage.log