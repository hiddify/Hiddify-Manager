source ../common/utils.sh
# latest= #$(get_release_version hiddify-sing-box)
latest=1.8.23
mkdir -p bin
if [ "$(cat VERSION 2>/dev/null)" != "$latest" ] || ! is_installed ./bin/xray; then
    pkg=$(dpkg --print-architecture)
    
    if [[ $pkg == "arm64" ]]; then
        curl -sLo sb.zip https://github.com/XTLS/Xray-core/releases/download/v$latest/Xray-linux-arm64-v8a.zip > /dev/null
    else
        curl -sLo sb.zip https://github.com/XTLS/Xray-core/releases/download/v$latest/Xray-linux-64.zip > /dev/null
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
