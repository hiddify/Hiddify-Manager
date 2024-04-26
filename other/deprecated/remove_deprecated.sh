systemctl stop --now shadowtls >/dev/null 2>&1
systemctl disable shadowtls >/dev/null 2>&1
rm -rf /opt/hiddify-manager/other/shadowtls/