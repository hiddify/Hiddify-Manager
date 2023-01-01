echo "shadowsocks proxy install.sh $*"
systemctl kill ss-v2ray.service
systemctl kill ss-faketls.service

apt-get install -y  shadowsocks-libev simple-obfs

wget -c https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-$(dpkg --print-architecture)-v1.3.2.tar.gz
tar xvzf v2ray-plugin-linux-*
mv v2ray-plugin_linux_$(dpkg --print-architecture) v2ray-plugin_linux






# if [[ "$1" ]]; then
# 	sed -i "s/defaultusersecret/$1/g" config-*.json
# fi

