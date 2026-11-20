ln -sf "$(pwd)/mtproxy.service" /etc/systemd/system/mtproxy.service
systemctl enable mtproxy.service
chmod 600 config.toml
systemctl restart mtproxy.service

systemctl status mtproxy --no-pager
