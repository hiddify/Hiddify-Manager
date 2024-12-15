source ../common/utils.sh
activate_python_venv

echo -n "" >> ../log/system/panel.log
chown hiddify-panel ../log/system/panel.log

chown -R hiddify-panel:hiddify-panel . >/dev/null 2>&1
chmod 600 app.cfg


# set mysql password to flask app config
sed -i '/^SQLALCHEMY_DATABASE_URI/d' app.cfg
if [ -z "${SQLALCHEMY_DATABASE_URI}" ]; then
    MYSQL_PASS=$(cat ../other/mysql/mysql_pass)
    SQLALCHEMY_DATABASE_URI="mysql+mysqldb://hiddifypanel:$MYSQL_PASS@localhost/hiddifypanel?charset=utf8mb4"
fi
echo "SQLALCHEMY_DATABASE_URI ='$SQLALCHEMY_DATABASE_URI'" >>app.cfg

sed -i '/^REDIS_URI/d' app.cfg
if [ -z "${REDIS_URI_MAIN}" ]; then
    REDIS_PASS=$(grep '^requirepass' "../other/redis/redis.conf" | awk '{print $2}')
    REDIS_URI_MAIN="redis://:${REDIS_PASS}@127.0.0.1:6379/0"
    REDIS_URI_SSH="redis://:${REDIS_PASS}@127.0.0.1:6379/1"
fi

echo "REDIS_URI_MAIN = '$REDIS_URI_MAIN'">>app.cfg
echo "REDIS_URI_SSH = '$REDIS_URI_SSH'">>app.cfg



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

systemctl start hiddify-panel.service
systemctl restart hiddify-panel-background-tasks.service

