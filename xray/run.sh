mv /usr/local/etc/xray/config.json /usr/local/etc/xray/config.json.old
# ln -s $(pwd)/xtls-config.json /usr/local/etc/xray/config.json
ln -s $(pwd)/xtls-sni-config.json /usr/local/etc/xray/config.json
sed -i "s/^User=/#User=/g" /etc/systemd/system/xray.service

systemctl daemon-reload

systemctl restart xray
