systemctl kill hiddify-sniproxy > /dev/null 2>&1
systemctl stop hiddify-sniproxy > /dev/null 2>&1
systemctl disable hiddify-sniproxy > /dev/null 2>&1

systemctl kill haproxy > /dev/null 2>&1
systemctl stop haproxy > /dev/null 2>&1
systemctl disable haproxy > /dev/null 2>&1
# pkill -9 haproxy
pkill -9 sniproxy > /dev/null 2>&1
if ! command -v haproxy ;then
    add-apt-repository ppa:vbernat/haproxy-2.7 -y
    apt update
    apt install haproxy=2.7.\* -y
fi
ln -sf $(pwd)/hiddify-haproxy.service /etc/systemd/system/hiddify-haproxy.service
systemctl enable hiddify-haproxy.service

rm haproxy.cfg*