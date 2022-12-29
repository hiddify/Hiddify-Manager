echo "telegram proxy install.sh $*"
systemctl stop mtproxy.service
systemctl disable mtproxy.service
systemctl stop mtproto-proxy.service
systemctl disable mtproto-proxy.service


apt install -y git curl make golang golang-go
ln -s  $(pwd)/mtproxy.service /etc/systemd/system/

git clone https://github.com/9seconds/mtg/
cd mtg

make 


