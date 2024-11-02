source /opt/hiddify-manager/common/utils.sh
install_package python3 python3-uvloop python3-cryptography python3-socks libcap2-bin

useradd --no-create-home -s /usr/sbin/nologin tgproxy
git clone https://github.com/hiddify/mtprotoproxy
cp config.py mtprotoproxy/config.py
