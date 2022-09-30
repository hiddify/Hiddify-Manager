apk install  apt-transport-https ca-certificates curl wget gnupg-agent software-properties-common git
mkdir -p /opt/gost
cd /opt/gost
wget https://github.com/ginuerzh/gost/releases/download/v2.11.4/gost-linux-amd64-2.11.4.gz
gunzip gost*
mv gost* gost
chmod +x gost
wget https://raw.githubusercontent.com/hiddify/config/main/gost.service
wget https://raw.githubusercontent.com/hiddify/config/main/clash_url.service
wget https://raw.githubusercontent.com/hiddify/config/main/clash_url.py
chmod +x clash_url.py
if [[ "$1" ]]; then
sed -i "s/00000000000000000000000000000001/$1/g" clash_url.py
sed -i "s/user:pass/$1:1/g" gost.service
fi

if [[ "$2" ]]; then
domain=$2

fi
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 3650 -nodes -subj "/C=GB/ST=London/L=London/O=Google Trust Services LLC/CN=www.google.com"
sudo mv gost.service /etc/systemd/system/
sudo mv clash_url.service /etc/systemd/system/
sudo systemctl enable gost.service
sudo systemctl start gost.service
sudo systemctl enable clash_url.service
sudo systemctl start clash_url.service
