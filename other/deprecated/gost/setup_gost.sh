#!/bin/bash

apt-get update
apt-get install -y apt-transport-https ca-certificates curl wget gnupg-agent software-properties-common git nginx certbot python3-certbot-nginx

mkdir -p /opt/gost
cd /opt/gost

wget https://github.com/ginuerzh/gost/releases/download/v2.11.4/gost-linux-amd64-2.11.4.gz
gunzip gost*
mv gost* gost
chmod +x gost

wget https://raw.githubusercontent.com/hiddify/config/main/gost/gost.service
wget https://raw.githubusercontent.com/hiddify/config/main/gost/nginx.conf
wget https://raw.githubusercontent.com/hiddify/config/main/gost/nginx-sni-proxy.conf

rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default
ln -sf $(pwd)/nginx.conf /etc/nginx/conf.d/site.conf
mkdir -p /etc/nginx/stream.d/ && ln -sf $(pwd)/nginx-sni-proxy.conf /etc/nginx/stream.d/nginx-sni-proxy.conf
echo "include /etc/nginx/stream.d/*.conf">>/etc/nginx/nginx.conf;
ln -sf $(pwd)/gost.service /etc/systemd/system/gost.service

wget -qO- https://raw.githubusercontent.com/hiddify/config/main/google-bbr.sh | bash



if [[ "$1" ]]; then
	sed -i "s/nginxusersecret/$1/g" nginx.conf
	sed -i "s/user:pass/$1:1/g" gost.service
fi

if [[ "$2" ]]; then
	domain=$2
	echo $domain>domain
	sed -i "s/nginxserverhost/$2/g" nginx.conf
	sed -i "s/nginxserverhost/$2/g" nginx-sni-proxy.conf
	certbot --nginx --register-unsafely-without-email -d $domain --non-interactive --agree-tos  --https-port 444
	sed -i "s/listen 444 ssl;/listen 444 ssl http2;/" nginx.conf
fi

openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 3650 -nodes -subj "/C=GB/ST=London/L=London/O=Google Trust Services LLC/CN=www.google.com"

systemctl enable gost.service
systemctl start gost.service
systemctl restart nginx
