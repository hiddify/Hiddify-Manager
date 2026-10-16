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