source /opt/hiddify-manager/common/utils.sh

install_package shadowsocks-libev simple-obfs
chmod 600 *.service*
ln -sf $(pwd)/hiddify-ss-faketls.service /etc/systemd/system/hiddify-ss-faketls.service
systemctl disable --now ss-faketls.service > /dev/null 2>&1
rm ss-faketls.service* > /dev/null 2>&1