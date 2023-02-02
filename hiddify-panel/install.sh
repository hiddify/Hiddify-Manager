
systemctl kill hiddify-admin.service
systemctl disable hiddify-admin.service

for req in pip hiddifypanel;do
    which $req
    if [[ "$?" != 0 ]];then
            apt update
            apt install -y python3-pip
            break
    fi
done

pip --disable-pip-version-check install -q -U hiddifypanel
hiddifypanel init-db
ln -sf $(pwd)/hiddify-panel.service /etc/systemd/system/hiddify-panel.service
systemctl enable hiddify-panel.service
if [ -f "../config.env" ]; then
    hiddifypanel import-config -c $(pwd)/../config.env
    if [ "$?" == 0 ];then
            # rm config.env
            echo "temporary disable removing config.env"
    fi
fi

echo "*/5 * * * * root $(pwd)/update_usage.sh" > /etc/cron.d/hiddify_usage_update
service cron reload


