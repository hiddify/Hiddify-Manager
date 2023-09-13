latest=$(get_release_version ssh-liberty-bridge)

if [ "$(cat VERSION)" != $latest ]; then
    curl -L -o ssh-liberty-bridge https://github.com/hiddify/ssh-liberty-bridge/releases/latest/download/ssh-liberty-bridge-$(dpkg --print-architecture)
    chmod +x ssh-liberty-bridge
    echo $latest >VERSION
    useradd liberty-bridge
fi

if [[ ! -d host_key ]]; then
    mkdir -p ./tmp/etc/ssh/
    ssh-keygen -A -f ./tmp/ # Creates the required keys in /tmp/etc/ssh
    rm ./tmp/etc/ssh/ssh_host_dsa_key*
    rm ./tmp/etc/ssh/ssh_host_rsa_key*
    mkdir -p host_key
    cp ./tmp/etc/ssh/* host_key/
    rm -rf ./tmp
fi
chown -R liberty-bridge host_key
