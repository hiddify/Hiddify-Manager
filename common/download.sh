#!/bin/bash

if [[ "$VER" != "" ]];then
    set -- $VER  $@

fi

echo "$0 input params are $@"


if [[ " $@ " != *"--no-gui"* ]] &&  [[ "$0" == "bash" ]]; then
    echo "This script is deprecated! Please use the following command"
    echo ""
    echo "bash <(curl i.hiddify.com/$1)"
    echo ""
    exit 1
fi

echo "Downloading '$@'"

if [[ " $@ " == *" release "* || " $@ " == *" v8 "* ]]; then
    sudo bash -c "$(curl -sLfo- https://raw.githubusercontent.com/hiddify/hiddify-config/main/common/download_install.sh)"
    exit $?
fi

mkdir -p /tmp/hiddify/
curl -sL -o /tmp/hiddify/hiddify_installer.sh https://raw.githubusercontent.com/hiddify/Hiddify-Manager/main/common/hiddify_installer.sh
curl -sL -o /tmp/hiddify/utils.sh https://raw.githubusercontent.com/hiddify/Hiddify-Manager/main/common/utils.sh
chmod +x /tmp/hiddify/hiddify_installer.sh
chmod +x /tmp/hiddify/utils.sh
/tmp/hiddify/hiddify_installer.sh $@
