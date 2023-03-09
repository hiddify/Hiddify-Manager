
systemctl kill hiddify-admin.service
systemctl disable hiddify-admin.service

for req in pip3 uwsgi  python3 hiddifypanel lastversion jq;do
    which $req
    if [[ "$?" != 0 ]];then
            apt --fix-broken install -y
            apt update
            apt install -y python3-pip jq
            pip3 install pip
            pip3 install -U hiddifypanel lastversion  uwsgi
            break
    fi
done



# ln -sf $(which gunicorn) /usr/bin/gunicorn

#pip3 --disable-pip-version-check install -q -U hiddifypanel
# pip uninstall -y hiddifypanel 
# pip --disable-pip-version-check install -q -U git+https://github.com/hiddify/HiddifyPanel

# ln -sf $(which gunicorn) /usr/bin/gunicorn
ln -sf $(uwsgi) /usr/local/bin/uwsgi
hiddifypanel init-db
ln -sf $(pwd)/hiddify-panel.service /etc/systemd/system/hiddify-panel.service
systemctl enable hiddify-panel.service
if [ -f "../config.env" ]; then
    hiddifypanel import-config -c $(pwd)/../config.env
    if [ "$?" == 0 ];then
            rm -f config.env
            # echo "temporary disable removing config.env"
    fi
fi
systemctl daemon-reload
echo "*/10 * * * * root $(pwd)/update_usage.sh" > /etc/cron.d/hiddify_usage_update
service cron reload

systemctl start hiddify-panel.service
systemctl status hiddify-panel.service


echo "0 */6 * * * root $(pwd)/backup.sh" > /etc/cron.d/hiddify_auto_backup
service cron reload