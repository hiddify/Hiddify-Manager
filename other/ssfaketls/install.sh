source /opt/hiddify-manager/common/utils.sh

install_package shadowsocks-libev simple-obfs

ln -sf $(pwd)/hiddify-ss-faketls.service /etc/systemd/system/hiddify-ss-faketls.service
systemctl disable --now ss-faketls.service
rm ss-faketls.service*
