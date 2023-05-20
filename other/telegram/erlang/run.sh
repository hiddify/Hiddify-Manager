# systemctl enable mtproxy.service
# systemctl restart mtproxy.service

cd mtproto_proxy
sudo make update-sysconfig 

sudo systemctl enable mtproto-proxy
sudo systemctl restart mtproto-proxy
systemctl status mtproto-proxy --no-pager