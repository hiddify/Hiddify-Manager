echo "shadowsocks proxy install.sh $*"
systemctl kill ss-faketls.service

apt-get install -y  shadowsocks-libev simple-obfs



ln -sf $(pwd)/ss-faketls.service /etc/systemd/system/ss-faketls.service



# if [[ "$1" ]]; then
# 	sed -i "s/defaultusersecret/$1/g" config-*.json
# fi

