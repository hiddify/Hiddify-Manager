ln -sf $(pwd)/hiddify-telegram-proxy.service /etc/systemd/system/hiddify-telegram-proxy.service
echo "ln -sf  $(pwd)/hiddify-telegram-proxy.service /etc/systemd/system/hiddify-telegram-proxy.service"
cp config.py mtprotoproxy/config.py
systemctl enable hiddify-telegram-proxy.service
chmod 600 *.py*
systemctl restart hiddify-telegram-proxy.service
systemctl status hiddify-telegram-proxy --no-pager
