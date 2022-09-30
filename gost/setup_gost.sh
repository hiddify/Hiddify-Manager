apk install apt-transport-https ca-certificates curl wget gnupg-agent software-properties-common git nginx certbot python3-certbot-nginx
mkdir -p /opt/gost
cd /opt/gost
wget https://github.com/ginuerzh/gost/releases/download/v2.11.4/gost-linux-amd64-2.11.4.gz
gunzip gost*
mv gost* gost
chmod +x gost
wget https://raw.githubusercontent.com/hiddify/config/main/gost/gost.service
wget https://raw.githubusercontent.com/hiddify/config/main/gost/nginx.conf

rm /etc/nginx/site-available/default
ln -s $(pwd)/nginx.conf /etc/nginx/site-available/default 

if [[ "$1" ]]; then
	sed -i "s/nginxusersecret/$1/g" nginx.conf
	sed -i "s/user:pass/$1:1/g" gost.service
fi

if [[ "$2" ]]; then
	domain=$2
	echo $domain>domain
	sed -i "s/nginxserverhost/$2/g" nginx.conf
	certbot --nginx --register-unsafely-without-email -d $domain --non-interactive --agree-tos  --https-port 444
fi
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 3650 -nodes -subj "/C=GB/ST=London/L=London/O=Google Trust Services LLC/CN=www.google.com"
ln -s $(pwd)/gost.service /etc/systemd/system/gost.service
sudo systemctl enable gost.service
sudo systemctl start gost.service
