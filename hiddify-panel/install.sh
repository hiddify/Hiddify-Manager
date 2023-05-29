systemctl kill hiddify-admin.service  > /dev/null 2>&1
systemctl disable hiddify-admin.service > /dev/null 2>&1

useradd -m hiddify-panel
chown -R hiddify-panel:hiddify-panel  .
# apt install -y python3-dev
for req in pip3 uwsgi  python3 hiddifypanel lastversion jq;do
    which $req > /dev/null 2>&1
    if [[ "$?" != 0 ]];then
            apt --fix-broken install -y
            apt update
            apt install -y python3-pip jq python3-dev
            pip3 install pip 
            pip3 install -U hiddifypanel lastversion  uwsgi "requests<=2.29.0"
            break
    fi
done



# ln -sf $(which gunicorn) /usr/bin/gunicorn

#pip3 --disable-pip-version-check install -q -U hiddifypanel
# pip uninstall -y hiddifypanel 
# pip --disable-pip-version-check install -q -U git+https://github.com/hiddify/HiddifyPanel

# ln -sf $(which gunicorn) /usr/bin/gunicorn
ln -sf $(which uwsgi) /usr/local/bin/uwsgi
# hiddifypanel init-db
ln -sf $(pwd)/hiddify-panel.service /etc/systemd/system/hiddify-panel.service
systemctl enable hiddify-panel.service
if [ -f "../config.env" ]; then
    su hiddify-panel -c "hiddifypanel import-config -c $(pwd)/../config.env"
    if [ "$?" == 0 ];then
            rm -f config.env
            # echo "temporary disable removing config.env"
    fi
fi
systemctl daemon-reload
echo "*/1 * * * * root $(pwd)/update_usage.sh" > /etc/cron.d/hiddify_usage_update
service cron reload

systemctl start hiddify-panel.service
systemctl status hiddify-panel.service --no-pager


echo "0 */6 * * * hiddify-panel $(pwd)/backup.sh" > /etc/cron.d/hiddify_auto_backup
service cron reload


##### download videos

if [[ -e "GeoLite2-ASN.mmdb" && $(find "GeoLite2-ASN.mmdb" -mtime +1) ]]; then
    wget -O GeoLite2-ASN.mmdb      https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb  
fi
if [[ -e "GeoLite2-Country.mmdb" && $(find "GeoLite2-Country.mmdb" -mtime +1) ]]; then
    wget -O GeoLite2-Country.mmdb  https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb 
fi


bash download_yt.sh & 