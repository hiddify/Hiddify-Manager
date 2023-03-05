systemctl kill hiddify-sniproxy
systemctl stop hiddify-sniproxy
systemctl disable hiddify-sniproxy
pkill -9 sniproxy

apt install haproxy -y
