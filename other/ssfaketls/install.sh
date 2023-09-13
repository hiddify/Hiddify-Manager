echo "shadowsocks proxy install.sh $*"

install_package shadowsocks-libev simple-obfs

ln -sf $(pwd)/ss-faketls.service /etc/systemd/system/ss-faketls.service
