apt install sniproxy -y

systemctl disable sniproxy
kill -9 `lsof -t -i:443`
kill -9 `lsof -t -i:80`
ln -sf $(pwd)/hiddify-sniproxy.service /etc/systemd/system/hiddify-sniproxy.service
systemctl enable hiddify-sniproxy.service
