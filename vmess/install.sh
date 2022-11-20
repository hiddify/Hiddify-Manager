
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

rm /usr/local/etc/v2ray/config.json

ln -s $(pwd)/config.json /usr/local/etc/v2ray/config.json



