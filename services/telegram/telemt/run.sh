ln -sf $(pwd)/mtproxy.service /etc/systemd/system/mtproxy.service
systemctl enable mtproxy.service

generated="/opt/hiddify-manager/generated/telemt.toml"
if [ ! -s "$generated" ]; then
    echo "Missing $generated"
    exit 1
fi
ln -sfn "$generated" "$(pwd)/config.toml"

systemctl restart mtproxy.service
systemctl status mtproxy --no-pager
