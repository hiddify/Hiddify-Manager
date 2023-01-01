systemctl kill mtproxy.service

ln -s  $(pwd)/mtproxy.service /etc/systemd/system/mtproxy.service
systemctl enable mtproxy.service
systemctl restart mtproxy.service

