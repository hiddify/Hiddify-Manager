echo "telegram proxy install.sh $*"
systemctl stop mtproxy.service
systemctl disable mtproxy.service
systemctl stop mtproto-proxy.service
systemctl disable mtproto-proxy.service


apt install -y git curl build-essential libssl-dev zlib1g-dev
ln -s  $(pwd)/mtproxy.service /etc/systemd/system/

git clone https://github.com/krepver/MTProxy/
cd MTProxy
git checkout gcc10

make 

cd objs/bin

curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf

