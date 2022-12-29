echo "telegram proxy install.sh $*"
systemctl stop mtproxy.service
systemctl disable mtproxy.service
systemctl stop mtproto-proxy.service
systemctl disable mtproto-proxy.service
systemctl daemon-reload
sudo add-apt-repository -y ppa:longsleep/golang-backports
sudo apt update
apt install -y make golang 

# wget -c https://go.dev/dl/go1.19.linux-amd64.tar.gz  
# tar -xvf go1.19.linux-amd64.tar.gz   
# export PATH=$(pwd)/go/bin:$PATH

ln -s  $(pwd)/mtproxy.service /etc/systemd/system/mtproxy.service

export GOPATH=/opt/hiddify-config/telegram/go/
git clone https://github.com/9seconds/mtg/

cd mtg

make 


