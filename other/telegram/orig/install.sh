echo "telegram proxy install.sh $*"
systemctl stop mtproxy.service >/dev/null 2>&1
systemctl disable mtproxy.service >/dev/null 2>&1
systemctl stop mtproto-proxy.service >/dev/null 2>&1
systemctl disable mtproto-proxy.service >/dev/null 2>&1

install_package git curl build-essential libssl-dev zlib1g-dev

git clone https://github.com/hiddify/MTProxy > dev/null
cd MTProxy

make

cd objs/bin

curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
