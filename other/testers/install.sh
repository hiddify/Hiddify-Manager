#!/bin/bash
source ../../common/utils.sh


latest=$(get_release_version hiddify-next-core)

if [ "$(cat 'VERSION' 2>/dev/null)" != "$latest" ] || ! is_installed ./HiddifyCli; then
    echo "Downloading HiddifyCli..."
    pkg=$(dpkg --print-architecture)

    curl -Lo hiddify-cli.tar.gz https://github.com/hiddify/hiddify-next-core/releases/download/v$latest/hiddify-cli-linux-$pkg.tar.gz

    tar -xzf hiddify-cli.tar.gz
    rm  hiddify-cli.tar.gz
    echo $latest> VERSION
    echo "The HiddifyCli installed"
else
    echo "HiddifyCli is installed"
fi

ln -sf /opt/hiddify-manager/other/testers/hiddify-cli.service /etc/systemd/system/hiddify-cli.service
systemctl enable hiddify-cli.service