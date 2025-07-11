source /opt/hiddify-manager/common/package_manager.sh

echo "telegram proxy install.sh $*"
systemctl kill mtproxy.service >/dev/null 2>&1
systemctl disable mtproxy.service >/dev/null 2>&1

# sudo add-apt-repository -y ppa:longsleep/golang-backports
# sudo apt update
# apt install -y make golang

# wget -q --show-progress -c https://go.dev/dl/go1.19.linux-$pkg.tar.gz
# tar -xf go1.19.linux-amd64.tar.gz
# export PATH=$(pwd)/go/bin:$PATH

download_package mtproxygo mtg-linux.tar.gz
tar -xf mtg-linux.tar.gz || exit 1
rm -rf mtg-linux 
mv mtg*/mtg mtg || exit 2
set_installed_version mtproxygo
# export GOPATH=/opt/hiddify-manager/other/telegram/tgo/go/
# export GOCACHE=/opt/hiddify-manager/other/telegram/tgo/gocache/
# git clone https://github.com/9seconds/mtg/

# if [ ! -f mtg/mtg ];then
#     echo "error in installation of telegram"
#     cd mtg

#     make

# fi
