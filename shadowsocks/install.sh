echo "shadowsocks proxy install.sh $*"

apt-get install -y apt-transport-https ca-certificates curl wget gnupg-agent software-properties-common git shadowsocks-libev simple-obfs

wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
tar xvzf v2ray-plugin-linux-amd64*


ln -s $(pwd)/ss-faketls.service /etc/systemd/system/ss-faketls.service
ln -s $(pwd)/ss-v2ray.service /etc/systemd/system/ss-v2ray.service




if [[ "$1" ]]; then
	sed -i "s/defaultusersecret/$1/g" config-*.json
fi

systemctl enable ss-v2ray.service
systemctl enable ss-faketls.service
systemctl start ss-v2ray.service
systemctl start ss-faketls.service

