
apt install -y python3-pip
pip install -U hiddifypanel

ln -sf $(pwd)/hiddify-panel.service /etc/systemd/system/hiddify-panel.service
systemctl enable hiddify-panel.service
if [ -f "../config.env" ]; then
    hiddifypanel import_config $(pwd)/../config.env
    if [ "$?" == 0 ];then
            # rm config.env
    fi
fi

echo "*/5 * * * * root $(pwd)/update_usage.sh" > /etc/cron.d/hiddify_usage_update
service cron reload


