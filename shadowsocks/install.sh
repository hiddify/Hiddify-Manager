echo "shadowsocks proxy install.sh $*"
systemctl stop ss-v2ray.service
systemctl stop ss-faketls.service

apt-get install -y  shadowsocks-libev simple-obfs

wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-$(dpkg --print-architecture)-v1.3.2.tar.gz
tar xvzf v2ray-plugin-linux-*
mv v2ray-plugin-linux-$(dpkg --print-architecture) v2ray-plugin-linux


ln -s $(pwd)/ss-faketls.service /etc/systemd/system/ss-faketls.service
ln -s $(pwd)/ss-v2ray.service /etc/systemd/system/ss-v2ray.service




# if [[ "$1" ]]; then
# 	sed -i "s/defaultusersecret/$1/g" config-*.json
# fi

