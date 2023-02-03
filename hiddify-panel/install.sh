
systemctl kill hiddify-admin.service
systemctl disable hiddify-admin.service

for req in pip gunicorn;do
    which $req
    if [[ "$?" != 0 ]];then
            apt update
            apt install -y python3-pip gunicorn
            break
    fi
done

# pip --disable-pip-version-check install -q -U hiddifypanel==0.8.6
pip uninstall -y hiddifypanel 
pip --disable-pip-version-check install -q -U git+https://github.com/hiddify/HiddifyPanel

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
systemctl daemon-reload
echo "*/1 * * * * root $(pwd)/update_usage.sh" > /etc/cron.d/hiddify_usage_update
service cron reload


