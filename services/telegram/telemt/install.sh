source /opt/hiddify-manager/scripts/common/package_manager.sh

download_package telemt telemt.tar.gz
if [ "$?" == "0"  ] || ! is_installed ./telemt; then
    tar -xf telemt.tar.gz || exit 1
    rm -rf telemt.tar.gz
    set_installed_version telemt
fi



