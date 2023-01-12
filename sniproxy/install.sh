apt install sniproxy -y

systemctl disable sniproxy
ln -sf $(pwd)/hiddify-sniproxy.service /etc/systemd/system/hiddify-sniproxy.service
systemctl enable hiddify-sniproxy.service
