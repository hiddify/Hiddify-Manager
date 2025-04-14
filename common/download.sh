#!/bin/bash

if [[ "$VER" != "" ]];then
    set -- $VER  $@

fi

echo "$0 input params are $@"


if [[ " $@ " != *"--no-gui"* ]] &&  [[ "$0" == "bash" ]]; then
    echo "This script is deprecated! Please use the following command"
    echo ""
    echo "bash <(curl https://i.hiddify.com/$1)"
    echo ""
    exit 1
fi

echo "Downloading '$@'"

if [[ " $@ " == *" v8 "* ]]; then
    sudo bash -c "$(curl -sLfo- https://raw.githubusercontent.com/hiddify/hiddify-config/main/common/download_install.sh)"
    exit $?
fi


mkdir -p /tmp/hiddify/
chmod 600 /tmp/hiddify/
rm -rf /tmp/hiddify/*

if [ "$1" == "v*" ];then
    base_url=https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/tags/$1/
else 
    base_url=https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/$1/
fi
curl -sL -o /tmp/hiddify/hiddify_installer.sh $base_url/common/hiddify_installer.sh
curl -sL -o /tmp/hiddify/utils.sh $base_url/common/utils.sh
chmod 700 /tmp/hiddify/*

/tmp/hiddify/hiddify_installer.sh $@
