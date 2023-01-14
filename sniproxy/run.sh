# rm /etc/sniproxy.conf
# ln -sf $(pwd)/sniproxy.conf /etc/sniproxy.conf

pkill -9 sniproxy
systemctl restart hiddify-sniproxy.service