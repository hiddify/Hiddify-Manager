systemctl stop hiddify-telegram-proxy > /dev/null 2>&1
systemctl disable hiddify-telegram-proxy > /dev/null 2>&1
# Old unit names (the service was called mtproxy before)
systemctl disable --now mtproxy > /dev/null 2>&1
rm -f /etc/systemd/system/mtproxy.service
systemctl stop mtproto-proxy > /dev/null 2>&1
systemctl disable mtproto-proxy > /dev/null 2>&1
