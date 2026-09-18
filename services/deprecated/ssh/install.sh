source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh
cd "$(dirname -- "$0")"

SSH_DATA="$HIDDIFY_DATA/services/ssh"
mkdir -p "$SSH_DATA/host_key" "$SSH_DATA/ssh-users"

if [ -d host_key ] && [ ! -L host_key ]; then
    if [ -z "$(ls -A "$SSH_DATA/host_key" 2>/dev/null)" ] && [ -n "$(ls -A host_key 2>/dev/null)" ]; then
        cp -a host_key/. "$SSH_DATA/host_key/"
    fi
    rm -rf host_key
fi
ln -sfn "$SSH_DATA/host_key" host_key
ln -sfn "$SSH_DATA/ssh-users" ssh-users

version="" #use specific version if needed otherwise it will use the latest
download_package ssh-liberty-bridge ssh-liberty-bridge $version
if [ "$?" == "0"  ] || ! is_installed ./ssh-liberty-bridge; then
    chmod +x ssh-liberty-bridge
    useradd liberty-bridge
    set_installed_version ssh-liberty-bridge $version
fi
chown -R liberty-bridge "$SSH_DATA"
chown liberty-bridge "$SSH_DATA/.env"* 2>/dev/null || true
