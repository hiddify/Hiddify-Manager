#!/bin/sh
if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
        exit 1
fi
export DEBIAN_FRONTEND=noninteractive
if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
        exit 1
fi

echo "we are going to download needed files:)"
GITHUB_REPOSITORY=hiddify-server
GITHUB_USER=hiddify
GITHUB_BRANCH_OR_TAG=main

# if [ ! -d "/opt/$GITHUB_REPOSITORY" ];then
apt update
apt upgrade -y
apt install -y curl unzip
# pip3 install lastversion "requests<=2.29.0"
# pip install lastversion "requests<=2.29.0"
mkdir -p /opt/$GITHUB_REPOSITORY
cd /opt/$GITHUB_REPOSITORY
curl -L -o hiddify-server.zip https://github.com/hiddify/hiddify-server/releases/latest/download/hiddify-server.zip
unzip -o hiddify-server.zip
rm hiddify-server.zip

bash install.sh
# exit 0
# fi

sed -i "s|/opt/hiddify-server/menu.sh||g" ~/.bashrc
sed -i "s|cd /opt/hiddify-server/||g" ~/.bashrc
echo "/opt/hiddify-server/menu.sh" >>~/.bashrc
echo "cd /opt/hiddify-server/" >>~/.bashrc

read -p "Press any key to go  to menu" -n 1 key
cd /opt/$GITHUB_REPOSITORY
bash menu.sh
