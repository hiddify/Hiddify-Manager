echo "telegram proxy install.sh $*"
systemctl kill mtproxy.service
systemctl disable mtproxy.service
systemctl kill mtproto-proxy.service
systemctl disable mtproto-proxy.service

sudo add-apt-repository -y ppa:longsleep/golang-backports
sudo apt update
apt install -y make golang 

# wget -c https://go.dev/dl/go1.19.linux-amd64.tar.gz  
# tar -xvf go1.19.linux-amd64.tar.gz   
# export PATH=$(pwd)/go/bin:$PATH



export GOPATH=/opt/hiddify-config/telegram/go/
git clone https://github.com/9seconds/mtg/

cd mtg

make 


