
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

rm /usr/local/etc/v2ray/config.json

ln -s $(pwd)/config.json /usr/local/etc/v2ray/config.json
guid="${1:0:8}-${1:8:4}-${1:12:4}-${1:16:4}-${1:20:12}"
sed -i "s/usersecret/$guid/g" config.json

systemctl enable v2ray
systemctl start v2ray
