source ../common/utils.sh
# latest= #$(get_release_version hiddify-sing-box)
latest=24.11.05
mkdir -p bin
if [ "$(cat VERSION 2>/dev/null)" != "$latest" ] || ! is_installed ./bin/xray; then
    pkg=$(dpkg --print-architecture)
    
    if [[ $pkg == "arm64" ]]; then
        download_and_check_hash sb.zip https://github.com/XTLS/Xray-core/releases/download/v$latest/Xray-linux-arm64-v8a.zip 1f7bb43988da027df886e9e2e9257b8d398f6659 || return $0
    else
        download_and_check_hash sb.zip https://github.com/XTLS/Xray-core/releases/download/v$latest/Xray-linux-64.zip 47115da913244205464e4eaab3668e72b1d90118 || return $0
    fi
    
    systemctl stop hiddify-xray.service > /dev/null 2>&1
    rm -rf bin/*
    install_package unzip
    unzip -o sb.zip -d bin/ > /dev/null
    echo $latest >VERSION
    rm -r sb.zip
    chown root:root bin/xray
    chmod +x bin/xray
    ln -sf /opt/hiddify-manager/xray/bin/xray /usr/bin/xray
fi

mkdir -p run
