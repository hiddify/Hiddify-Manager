source ../common/utils.sh
# latest= #$(get_release_version hiddify-sing-box)
latest=24.11.11
mkdir -p bin
if [ "$(cat VERSION 2>/dev/null)" != "$latest" ] || ! is_installed ./bin/xray; then
    pkg=$(dpkg --print-architecture)
    
    if [[ $pkg == "arm64" ]]; then
        download_and_check_hash sb.zip https://github.com/XTLS/Xray-core/releases/download/v$latest/Xray-linux-arm64-v8a.zip 85af5e3a4afbce06ea21e87ef2723c69839e0819 || return $0
    else
        download_and_check_hash sb.zip https://github.com/XTLS/Xray-core/releases/download/v$latest/Xray-linux-64.zip 3d7a4a9e911f0cbd1cf962880e466fe3a63604cc || return $0
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
