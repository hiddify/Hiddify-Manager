echo "telegram proxy install.sh $*"
systemctl stop mtproxy.service
systemctl disable mtproxy.service
systemctl stop mtproto-proxy.service
systemctl disable mtproto-proxy.service

install_package git curl build-essential libssl-dev zlib1g-dev

git clone https://github.com/hiddify/MTProxy
cd MTProxy

make

cd objs/bin

curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
