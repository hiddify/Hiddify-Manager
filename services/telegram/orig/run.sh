ln -sf  $(pwd)/mtproxy.service /etc/systemd/system/mtproxy.service
systemctl enable mtproxy.service
chmod 700 tgproxy_run.sh*
systemctl restart mtproxy.service

systemctl status mtproxy --no-pager