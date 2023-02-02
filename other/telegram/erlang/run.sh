# systemctl enable mtproxy.service
# systemctl restart mtproxy.service

cd mtproto_proxy
sudo make update-sysconfig 
sudo systemctl restart mtproxy
