source /opt/hiddify-manager/scripts/common/package_manager.sh

if download_package telego telego.tar.gz; then
    :
elif ! is_installed ./telego; then
    download_package telego telego.tar.gz force || exit 1
else
    exit 0
fi

tar -xzf telego.tar.gz telego || exit 1
rm -f telego.tar.gz
set_installed_version telego
