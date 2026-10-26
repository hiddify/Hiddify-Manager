source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh
source /opt/hiddify-manager/services/warp/usque/utils.sh
ensure_warp_data_links usque "$(pwd)"

version=""
download_package usque usque.zip $version
if [ "$?" == "0" ] || ! is_installed ./usque; then
    systemctl stop hiddify-warp.service >/dev/null 2>&1 || true
    install_package unzip
    rm -rf .usque_extract
    mkdir -p .usque_extract
    unzip -o usque.zip -d .usque_extract >/dev/null || exit 1
    # Release zip: usque binary at the root (plus README / LICENSE).
    install -m 755 .usque_extract/usque ./usque || exit 2
    rm -rf usque.zip .usque_extract
    set_installed_version usque $version
fi
chmod +x usque run-instance.sh
