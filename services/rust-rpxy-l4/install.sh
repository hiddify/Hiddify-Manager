source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh

version=0.2.3
mkdir -p bin 

download_package rpxy-l4 rpxy-l4.tar.gz "$version"
if [ "$?" == "0" ] || [ ! -x ./bin/rpxy-l4 ]; then
    systemctl stop hiddify-rpxy-l4.service >/dev/null 2>&1
    rm -rf bin/*
    tar -xzf rpxy-l4.tar.gz -C bin/ || exit 1
    mv bin/rpxy-l4-* bin/rpxy-l4 2>/dev/null || true
    chown root:root bin/rpxy-l4 || exit 2
    chmod +x bin/rpxy-l4 || exit 3
    ln -sf /opt/hiddify-manager/services/rust-rpxy-l4/bin/rpxy-l4 /usr/bin/rpxy-l4 || exit 4
    rm -f rpxy-l4.tar.gz
    set_installed_version rpxy-l4 "$version"
fi
