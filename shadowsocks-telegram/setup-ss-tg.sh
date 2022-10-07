
wget https://raw.githubusercontent.com/hiddify/config/main/shadowsocks/setup-ss.sh 
wget  https://raw.githubusercontent.com/hiddify/config/main/telegram/setup_telegram.sh

bash setup-ss.sh $1 $2
bash setup_telegram.sh $1 $2

sed -i 's/PORT = 443/PORT = 449/g' /opt/mtprotoproxy/config.py
sed -i 's/$name {/$name { mail.google.com 127.0.0.1:449;/g' /opt/shadowsocks/nginx-sni-proxy.conf








