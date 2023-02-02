echo "shadowsocks proxy install.sh $*"
systemctl kill ss-faketls.service

apt-get install -y  shadowsocks-libev simple-obfs







# if [[ "$1" ]]; then
# 	sed -i "s/defaultusersecret/$1/g" config-*.json
# fi

