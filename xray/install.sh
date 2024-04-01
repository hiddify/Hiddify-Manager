source ../common/utils.sh
# latest= #$(get_release_version hiddify-sing-box)
latest=1.8.10
mkdir -p bin
if [ "$(cat VERSION)" != "$latest" ] || ! is_installed ./bin/xray; then
    pkg=$(dpkg --print-architecture)

    if [[ $pkg == "arm64" ]]; then
        curl -Lo sb.zip https://github.com/XTLS/Xray-core/releases/download/v$latest/Xray-linux-arm64-v8a.zip
    else
        curl -Lo sb.zip https://github.com/XTLS/Xray-core/releases/download/v$latest/Xray-linux-64.zip
    fi
    systemctl stop hiddify-xray.service
    rm -rf bin/*
    install_package unzip
    unzip -o sb.zip -d bin/
    echo $latest >VERSION
    rm -r sb.zip
    chown root:root bin/xray
    chmod +x bin/xray
    ln -sf /opt/hiddify-manager/xray/bin/xray /usr/bin/xray
fi

mkdir -p run
