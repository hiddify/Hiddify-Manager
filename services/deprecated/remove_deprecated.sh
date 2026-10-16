# hiddify-cli (deprecated)
systemctl disable --now hiddify-cli.service >/dev/null 2>&1
rm -f /etc/systemd/system/hiddify-cli.service
rm -rf /opt/hiddify-manager/services/hiddify-cli/

systemctl stop --now shadowtls >/dev/null 2>&1
systemctl disable shadowtls >/dev/null 2>&1
rm -rf /opt/hiddify-manager/services/shadowtls/