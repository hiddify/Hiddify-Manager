#!/bin/bash
cd $( dirname -- "$0"; )
function main(){
    hiddifypanel update-usage
}
main |& tee -a ../log/system/update_usage.log