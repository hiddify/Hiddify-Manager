systemctl kill hiddify-sniproxy
systemctl stop hiddify-sniproxy
systemctl disable hiddify-sniproxy

systemctl kill haproxy
systemctl stop haproxy
systemctl disable haproxy
pkill -9 haproxy
pkill -9 sniproxy

add-apt-repository ppa:vbernat/haproxy-2.4 -y
apt update
apt install haproxy=2.4.\* -y

ln -sf $(pwd)/hiddify-haproxy.service /etc/systemd/system/hiddify-haproxy.service
systemctl enable hiddify-haproxy.service

rm haproxy.cfg*