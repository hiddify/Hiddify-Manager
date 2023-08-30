systemctl kill hiddify-admin.service >/dev/null 2>&1
systemctl disable hiddify-admin.service >/dev/null 2>&1
#userdel -f hiddify-panel 2>&1
useradd -m hiddify-panel -s /bin/bash >/dev/null 2>&1
chown -R hiddify-panel:hiddify-panel /home/hiddify-panel/ >/dev/null 2>&1
su hiddify-panel -c localectl set-locale LANG=C.UTF-8 >/dev/null 2>&1
su hiddify-panel -c update-locale LANG=C.UTF-8 >/dev/null 2>&1

chown -R hiddify-panel:hiddify-panel . >/dev/null 2>&1
# apt install -y python3-dev
for req in pip3 uwsgi python3 hiddifypanel lastversion jq sqlite3mysql; do
    which $req >/dev/null 2>&1
    if [[ "$?" != 0 ]]; then
        apt --fix-broken install -y
        apt update
        apt install -y python3-pip jq python3-dev
        pip3 install pip
        pip3 install -U hiddifypanel lastversion uwsgi "requests<=2.29.0" sqlite3-to-mysql
        break
    fi
done
(cd ../other/redis/ && bash install.sh)
(cd ../other/mysql/ && bash install.sh)

sed -i '/SQLALCHEMY_DATABASE_URI/d' app.cfg
MYSQL_PASS=$(cat ../other/mysql/mysql_pass)
echo "SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://hiddifypanel:$MYSQL_PASS@127.0.0.1/hiddifypanel'" >>app.cfg

# if [ -f hiddifypanel.db ]; then
#     sqlite3mysql -f hiddifypanel.db -d hiddifypanel -u hiddifypanel -h 127.0.0.1 --mysql-password $MYSQL_PASS
#     mv hiddifypanel.db hiddifypanel.db.old
# fi

# ln -sf $(which gunicorn) /usr/bin/gunicorn

#pip3 --disable-pip-version-check install -q -U hiddifypanel
# pip uninstall -y hiddifypanel
# pip --disable-pip-version-check install -q -U git+https://github.com/hiddify/HiddifyPanel

# ln -sf $(which gunicorn) /usr/bin/gunicorn
ln -sf $(which uwsgi) /usr/local/bin/uwsgi >/dev/null 2>&1
# hiddifypanel init-db
ln -sf $(pwd)/hiddify-panel.service /etc/systemd/system/hiddify-panel.service
systemctl enable hiddify-panel.service
if [ -f "../config.env" ]; then
    su hiddify-panel -c "hiddifypanel import-config -c $(pwd)/../config.env"
    if [ "$?" == 0 ]; then
        rm -f config.env
        # echo "temporary disable removing config.env"
    fi
fi
systemctl daemon-reload >/dev/null 2>&1
echo "*/1 * * * * root $(pwd)/update_usage.sh" >/etc/cron.d/hiddify_usage_update
service cron reload >/dev/null 2>&1

systemctl start hiddify-panel.service
# systemctl status hiddify-panel.service --no-pager > /dev/null 2>&1

echo "0 */6 * * * hiddify-panel $(pwd)/backup.sh" >/etc/cron.d/hiddify_auto_backup
service cron reload

##### download videos

if [[ ! -e "GeoLite2-ASN.mmdb" || $(find "GeoLite2-ASN.mmdb" -mtime +1) ]]; then
    curl --connect-timeout 10 -L -o GeoLite2-ASN.mmdb1 https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb && mv GeoLite2-ASN.mmdb1 GeoLite2-ASN.mmdb
fi
if [[ ! -e "GeoLite2-Country.mmdb" || $(find "GeoLite2-Country.mmdb" -mtime +1) ]]; then
    curl --connect-timeout 10 -L -o GeoLite2-Country.mmdb1 https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb && mv GeoLite2-Country.mmdb1 GeoLite2-Country.mmdb
fi

bash download_yt.sh &
