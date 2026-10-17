# Telegram proxies other than telemt (deprecated): erlang ran as mtproto-proxy; the others used hiddify-telegram-proxy,
# which telemt now owns and restarts itself.
systemctl disable --now mtproto-proxy.service >/dev/null 2>&1
rm -rf /opt/hiddify-manager/services/telegram/{erlang,orig,python,tgo}/
# The leftover templates would be rendered over the new install.sh / run.sh.
rm -f /opt/hiddify-manager/services/telegram/install.sh.j2 /opt/hiddify-manager/services/telegram/run.sh.j2

# v2ray (deprecated): the shadowsocks v2ray-plugin service
systemctl disable --now ss-v2ray.service >/dev/null 2>&1
rm -f /etc/systemd/system/ss-v2ray.service
rm -rf /opt/hiddify-manager/services/v2ray/

# hiddify-cli (deprecated)
systemctl disable --now hiddify-cli.service >/dev/null 2>&1
rm -f /etc/systemd/system/hiddify-cli.service
rm -rf /opt/hiddify-manager/services/hiddify-cli/

systemctl stop --now shadowtls >/dev/null 2>&1
systemctl disable shadowtls >/dev/null 2>&1
rm -rf /opt/hiddify-manager/services/shadowtls/
# nginx (deprecated in v14): it only served acme.sh's challenge files; HAProxy answers the ACME challenges now
# (hiddifypanel/acme). The nginx package stays installed.
systemctl disable --now hiddify-nginx.service >/dev/null 2>&1
rm -f /etc/systemd/system/hiddify-nginx.service
rm -rf /opt/hiddify-manager/services/nginx/ /opt/hiddify-manager/data/services/nginx/
rm -f /opt/hiddify-manager/generated/nginx.cfg
rm -rf /opt/hiddify-manager/generated/include/nginx/

# acme.sh (deprecated in v14): the panel issues the certificates (Let's Encrypt, ZeroSSL) and keeps them in its database
# (it imported acme.sh's data/ssl when upgrading). data/services/acme.sh (the old accounts) is kept as a backup.
if [ -d /opt/hiddify-manager/services/acme.sh ]; then
    crontab -l 2>/dev/null | grep -v "acme.sh" | crontab - 2>/dev/null
    rm -rf /opt/hiddify-manager/services/acme.sh/
fi
