systemctl kill mtproxy.service


ln -sf  $(pwd)/mtproxy.service /etc/systemd/system/mtproxy.service
systemctl enable mtproxy.service
systemctl restart mtproxy.service

systemctl status mtproxy --no-pager