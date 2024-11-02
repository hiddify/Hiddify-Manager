source /opt/hiddify-manager/common/utils.sh
latest=$(get_release_version ssh-liberty-bridge)

if [ "$(cat VERSION 2>/dev/null)" != $latest ]; then
    curl -sL -o ssh-liberty-bridge https://github.com/hiddify/ssh-liberty-bridge/releases/latest/download/ssh-liberty-bridge-$(dpkg --print-architecture)
    chmod +x ssh-liberty-bridge
    echo $latest >VERSION
    useradd liberty-bridge
fi
chown liberty-bridge .env* 
