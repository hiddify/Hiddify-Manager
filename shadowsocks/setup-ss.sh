apt update
apt-get install -y apt-transport-https ca-certificates curl wget gnupg-agent software-properties-common git nginx certbot python3-certbot-nginx shadowsocks-libev simple-obfs
mkdir -p /opt/shadowsocks
cd /opt/shadowsocks

wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
tar xvzf v2ray-plugin-linux-amd64*

wget https://raw.githubusercontent.com/hiddify/config/main/shadowsocks/ss-faketls.service
wget https://raw.githubusercontent.com/hiddify/config/main/shadowsocks/ss-v2ray.service
wget https://raw.githubusercontent.com/hiddify/config/main/shadowsocks/nginx-web.conf
wget https://raw.githubusercontent.com/hiddify/config/main/shadowsocks/nginx-sni-proxy.conf
wget https://raw.githubusercontent.com/hiddify/config/main/shadowsocks/config-v2ray.json
wget https://raw.githubusercontent.com/hiddify/config/main/shadowsocks/config-faketls.json

rm /etc/nginx/sites-available/default
ln -s $(pwd)/nginx-web.conf /etc/nginx/conf.d/web.conf
mkdir -p /etc/nginx/stream.d/ && ln -s $(pwd)/nginx-sni-proxy.conf /etc/nginx/stream.d/nginx-sni-proxy.conf
echo "include /etc/nginx/stream.d/*.conf">>/etc/nginx/nginx.conf;

ln -s $(pwd)/ss-faketls.service /etc/systemd/system/ss-faketls.service
ln -s $(pwd)/ss-v2ray.service /etc/systemd/system/ss-v2ray.service

wget -qO- https://raw.githubusercontent.com/hiddify/config/main/google-bbr.sh | bash



if [[ "$1" ]]; then
	sed -i "s/defaultusersecret/$1/g" nginx-web.conf
	sed -i "s/defaultusersecret/$1/g" config-*.json
fi

if [[ "$2" ]]; then
	domain=$2
	echo $domain>domain
	sed -i "s/defaultserverhost/$2/g" nginx-web.conf
	sed -i "s/defaultserverhost/$2/g" nginx-sni-proxy.conf
	certbot --nginx --register-unsafely-without-email -d $domain --non-interactive --agree-tos  --https-port 444
	sed -i "s/listen 444 ssl;/listen 444 ssl http2;/" nginx.conf
fi

systemctl enable ss-v2ray.service
systemctl enable ss-faketls.service
systemctl start ss-v2ray.service
systemctl start ss-faketls.service

systemctl restart nginx
