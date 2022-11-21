#!/bin/sh
if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
        exit 1
fi

echo "we are going to download needed files:)"

if [ ! -d "/opt/$GITHUB_REPOSITORY" ];then
        apt update
        apt install -y git
        git clone https://github.com/$GITHUB_USER/$GITHUB_REPOSITORY/  /opt/$GITHUB_REPOSITORY
        cd /opt/$GITHUB_REPOSITORY
        git checkout $GITHUB_BRANCH_OR_TAG
fi 


export USER_SECRET=$1
export MAIN_DOMAIN=$2

MODE="${3:-all}"
if [[ $MODE == 'all' ]]; then
  MODE="shadowsocks-telegram-vmess";
fi
if [[ $MODE == *'telegram'* ]]; then
  export ENABLE_TELEGRAM=true
fi
if [[ $MODE == *'shadowsocks'* ]]; then
   export ENABLE_SS=true
fi
if [[ $MODE == *'vmess'* ]]; then
   export ENABLE_VMESS=true
fi

cd /opt/$GITHUB_REPOSITORY
bash install.sh