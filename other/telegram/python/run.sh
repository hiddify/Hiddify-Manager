ln -sf $(pwd)/mtproxy.service /etc/systemd/system/mtproxy.service
echo "ln -sf  $(pwd)/mtproxy.service /etc/systemd/system/mtproxy.service"
cp config.py mtprotoproxy/config.py
systemctl enable mtproxy.service
chmod 600 *.py*
systemctl restart mtproxy.service
systemctl status mtproxy --no-pager
