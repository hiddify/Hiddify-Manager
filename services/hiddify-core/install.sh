source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh
rm -rf configs/*.template

# latest= #$(get_release_version hiddify-hiddify-core)
version="" #use specific version if needed otherwise it will use the latest



download_package hiddify-core sb.tar.gz $version
if [ "$?" == "0"  ] || ! is_installed ./hiddify-core; then
    tar -xzf sb.tar.gz  || exit 1
    cp -rf hiddify-core-*/. . || exit 2  # -r: the archive has a lib/ folder too
    # The archive too (~29 MB): the recorded version (set_installed_version below), not the file, skips the next download.
    # (This line removed a nonexistent sb.zip and failed on every run: no symlink, no recorded version, no tor.)
    rm -rf sb.tar.gz hiddify-core-*/ || exit 3
    chown root:root hiddify-core || exit 4
    chmod +x hiddify-core || exit 5
    ln -sf /opt/hiddify-manager/services/hiddify-core/hiddify-core /usr/bin/hiddify-core || exit 6
    rm geosite.db 2>/dev/null 
    set_installed_version hiddify-core $version
fi

# hiddify-core starts this program itself for the Tor outbound.
install_package tor
systemctl disable --now tor 2>/dev/null || true