#!/bin/sh
if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
        exit 1
fi
export DEBIAN_FRONTEND=noninteractive

echo "we are going to download needed files:)"
GITHUB_REPOSITORY=hiddify-config
GITHUB_USER=hiddify
GITHUB_BRANCH_OR_TAG=main

# if [ ! -d "/opt/$GITHUB_REPOSITORY" ];then
apt update
#apt upgrade -y
#apt -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

apt install -y curl unzip
# pip3 install lastversion "requests<=2.29.0"
# pip install lastversion "requests<=2.29.0"
mkdir -p /opt/$GITHUB_REPOSITORY
cd /opt/$GITHUB_REPOSITORY
curl -L -o $GITHUB_REPOSITORY.zip https://github.com/hiddify/$GITHUB_REPOSITORY/releases/download/v10.5.73/$GITHUB_REPOSITORY.zip
unzip -o $GITHUB_REPOSITORY.zip
rm $GITHUB_REPOSITORY.zip
rm -f xray/configs/*.json
rm -f singbox/configs/*.json
source /opt/hiddify-config/common/utils.sh
install_python
install_pypi_package pip==24.0 # pip install -U pip
pip install -U hiddifypanel==8.8.98
bash install.sh --no-gui
# exit 0
# fi

sed -i "s|/opt/$GITHUB_REPOSITORY/menu.sh||g" ~/.bashrc
sed -i "s|cd /opt/$GITHUB_REPOSITORY/||g" ~/.bashrc
echo "/opt/$GITHUB_REPOSITORY/menu.sh" >>~/.bashrc
echo "cd /opt/$GITHUB_REPOSITORY/" >>~/.bashrc
if [ "$CREATE_EASYSETUP_LINK" == "true" ];then
        cd /opt/$GITHUB_REPOSITORY/hiddify-panel
        hiddifypanel set_setting --key create_easysetup_link --value True
fi

# hiddifypanel set_setting --key auto_update --value False

read -p "Press any key to go  to menu" -n 1 key
cd /opt/$GITHUB_REPOSITORY
bash menu.sh
