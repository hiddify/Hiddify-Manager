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
GITHUB_REPOSITORY=hiddify-config
GITHUB_USER=hiddify
GITHUB_BRANCH_OR_TAG=main

# if [ ! -d "/opt/$GITHUB_REPOSITORY" ];then
        apt update
        apt upgrade -y
        apt install -y wget python3-pip
        pip3 install lastversion
        mkdir -p /opt/$GITHUB_REPOSITORY
        LAST_CONFIG_VERSION=$(lastversion $GITHUB_USER/$GITHUB_REPOSITORY)
        wget -c $(lastversion $GITHUB_USER/$GITHUB_REPOSITORY --source)
        tar xvzf $GITHUB_REPOSITORY-v$LAST_CONFIG_VERSION.tar.gz --strip-components=1 --directory /opt/$GITHUB_REPOSITORY
        rm $GITHUB_REPOSITORY-v$LAST_CONFIG_VERSION.tar.gz
        cd /opt/$GITHUB_REPOSITORY
        bash install.sh
        # exit 0
# fi 

read -p "Press any key to go  to menu" -n 1 key
cd /opt/$GITHUB_REPOSITORY
bash menu.sh
