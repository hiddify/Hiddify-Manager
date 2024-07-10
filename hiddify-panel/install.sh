source ../common/utils.sh
activate_python_venv
install_package wireguard libev-dev libevdev2 default-libmysqlclient-dev build-essential pkg-config

useradd -m hiddify-panel -s /bin/bash >/dev/null 2>&1
echo -n "" >> ../log/system/panel.log
chown hiddify-panel ../log/system/panel.log
chsh hiddify-panel -s /bin/bash

chown -R hiddify-panel:hiddify-panel /home/hiddify-panel/ >/dev/null 2>&1
localectl set-locale LANG=C.UTF-8 >/dev/null 2>&1
su hiddify-panel -c update-locale LANG=C.UTF-8 >/dev/null 2>&1
chown -R hiddify-panel:hiddify-panel . >/dev/null 2>&1
# activate venv for hiddify-panel user
if ! grep -Fxq "source /opt/hiddify-manager/.venv/bin/activate" "/home/hiddify-panel/.bashrc" && ! grep -Fxq "export PATH=/opt/hiddify-manager/.venv/bin:\$PATH" "/home/hiddify-panel/.bashrc"; then
    echo "source /opt/hiddify-manager/.venv/bin/activate" >> "/home/hiddify-panel/.bashrc"
    echo "export PATH=/opt/hiddify-manager/.venv/bin:\$PATH" >> "/home/hiddify-panel/.bashrc"
fi

pip uninstall -y flask-babelex >/dev/null 2>&1

# install/build hiddifypanel package
if [ "$HIDDIFY_DEBUG" = "1" ] && [ -n "$HIDDIFY_PANLE_SOURCE_DIR" ]; then
    echo "NOTICE: building hiddifypanel package from source..."
    echo "NOTICE: the source dir $HIDDIFY_PANLE_SOURCE_DIR"
    pip install -e "$HIDDIFY_PANLE_SOURCE_DIR"
else
    echo "Installing hiddifypanel with the pip"
    python -c "import hiddifypanel" || pip install -U hiddifypanel
fi


# set mysql password to flask app config
sed -i '/SQLALCHEMY_DATABASE_URI/d' app.cfg
MYSQL_PASS=$(cat ../other/mysql/mysql_pass)
echo "SQLALCHEMY_DATABASE_URI = 'mysql+mysqldb://hiddifypanel:$MYSQL_PASS@127.0.0.1/hiddifypanel?charset=utf8mb4'" >>app.cfg

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
    # systemctl restart --now mariadb
    # sleep 4
    
    hiddify-panel-cli import-config -c $(pwd)/../config.env
    
    # doesn't load virtual env
    #su hiddify-panel -c "hiddifypanel import-config -c $(pwd)/../config.env"
    
    if [ "$?" == 0 ]; then
        rm -f ../config.env
        # echo "temporary disable removing config.env"
    fi
fi
systemctl daemon-reload >/dev/null 2>&1

systemctl start hiddify-panel.service
echo "*/1 * * * * root $(pwd)/update_usage.sh" >/etc/cron.d/hiddify_usage_update
echo "0 */6 * * * hiddify-panel $(pwd)/backup.sh" >/etc/cron.d/hiddify_auto_backup
service cron reload >/dev/null 2>&1


##### download videos

if [[ ! -e "GeoLite2-ASN.mmdb" || $(find "GeoLite2-ASN.mmdb" -mtime +1) ]]; then
    curl --connect-timeout 10 -sL -o GeoLite2-ASN.mmdb1 https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb && mv GeoLite2-ASN.mmdb1 GeoLite2-ASN.mmdb
fi
if [[ ! -e "GeoLite2-Country.mmdb" || $(find "GeoLite2-Country.mmdb" -mtime +1) ]]; then
    curl --connect-timeout 10 -sL -o GeoLite2-Country.mmdb1 https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb && mv GeoLite2-Country.mmdb1 GeoLite2-Country.mmdb
fi

# bash download_yt.sh &
