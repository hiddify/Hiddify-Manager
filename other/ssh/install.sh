

wget https://github.com/hiddify/ssh-liberty-bridge/releases/latest/download/ssh-liberty-bridge-$(dpkg --print-architecture)

mv ssh-liberty-bridge-* ssh-liberty-bridge
chmod +x ssh-liberty-bridge

useradd liberty-bridge


if [[ ! -d host_key ]];then
    mkdir -p ./tmp/etc/ssh/
    ssh-keygen -A -f ./tmp/  # Creates the required keys in /tmp/etc/ssh
    rm ./tmp/etc/ssh/ssh_host_dsa_key*
    rm ./tmp/etc/ssh/ssh_host_rsa_key*
    mkdir -p host_key
    cp ./tmp/etc/ssh/* host_key/
    rm -rf ./tmp 
fi 
chown -R liberty-bridge host_key