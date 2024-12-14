source ../common/utils.sh
source ../common/package_manager.sh
# latest= #$(get_release_version hiddify-sing-box)
version="" #use specific version if needed otherwise it will use the latest
mkdir -p bin run


download_package xray sb.zip $version
if [ "$?" == "0"  ] || ! is_installed ./bin/xray; then
    systemctl stop hiddify-xray.service > /dev/null 2>&1 
    rm -rf bin/*
    install_package unzip 
    unzip -o sb.zip -d bin/ > /dev/null || exit 1
    rm -r sb.zip 
    chown root:root bin/xray || exit 2
    chmod +x bin/xray || exit 3
    ln -sf /opt/hiddify-manager/xray/bin/xray /usr/bin/xray || exit 3
    set_installed_version xray $version
fi
