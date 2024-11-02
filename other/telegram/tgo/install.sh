source /opt/hiddify-manager/common/utils.sh
echo "telegram proxy install.sh $*"
systemctl kill mtproxy.service >/dev/null 2>&1
systemctl disable mtproxy.service >/dev/null 2>&1

# sudo add-apt-repository -y ppa:longsleep/golang-backports
# sudo apt update
# apt install -y make golang

# wget -q --show-progress -c https://go.dev/dl/go1.19.linux-$pkg.tar.gz
# tar -xf go1.19.linux-amd64.tar.gz
# export PATH=$(pwd)/go/bin:$PATH
declare -A hashes=(
    ["arm64"]="e5f23c5e83018efcc8c13431ab06f04076d2a933"
    ["amd64"]="ea5ea6d8e654e6253b89d4c6f42947482b7064ff"
)

pkg=$(dpkg --print-architecture)
HASH=${hashes[$pkg]-:hashes[amd64]}

download_and_check_hash mtg-2.1.7-linux-$pkg.tar.gz https://github.com/XTLS/Xray-core/releases/download/v$latest/Xray-linux-64.zip $HASH || return $0
tar -xf mtg-2.1.7-linux-$pkg.tar.gz
rm -rf mtg
mv mtg-2.1.7-linux-$pkg/mtg mtg

# export GOPATH=/opt/hiddify-manager/other/telegram/tgo/go/
# export GOCACHE=/opt/hiddify-manager/other/telegram/tgo/gocache/
# git clone https://github.com/9seconds/mtg/

# if [ ! -f mtg/mtg ];then
#     echo "error in installation of telegram"
#     cd mtg

#     make

# fi
