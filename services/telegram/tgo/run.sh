systemctl kill mtproxy.service


ln -sf  $(pwd)/mtproxy.service /etc/systemd/system/mtproxy.service
systemctl enable mtproxy.service
chmod 600 *toml*
systemctl restart mtproxy.service

systemctl status mtproxy --no-pager