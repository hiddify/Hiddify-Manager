echo "telegram proxy install.sh $*"
systemctl kill mtproxy.service
systemctl disable mtproxy.service

# sudo add-apt-repository -y ppa:longsleep/golang-backports
# sudo apt update
# apt install -y make golang 

pkg=$(dpkg --print-architecture)

wget -q --show-progress -c https://go.dev/dl/go1.19.linux-$pkg.tar.gz  
tar -xf go1.19.linux-amd64.tar.gz   
export PATH=$(pwd)/go/bin:$PATH



export GOPATH=/opt/hiddify-config/other/telegram/tgo/go/
export GOCACHE=/opt/hiddify-config/other/telegram/tgo/gocache/
git clone https://github.com/9seconds/mtg/

cd mtg

make 


