source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/mysql/utils.sh
source /opt/hiddify-manager/services/redis/utils.sh
activate_python_venv

mkdir -p "$HIDDIFY_DATA/hiddify-panel" "$HIDDIFY_DATA/log/system"

PANEL_DIR="/opt/hiddify-manager/services/hiddify-panel"
APP_CFG="$HIDDIFY_PANEL_CFG_PATH"
TEMPLATE_CFG="$PANEL_DIR/app.cfg"

echo -n "" >> /opt/hiddify-manager/data/log/system/panel.log
chown hiddify-panel /opt/hiddify-manager/data/log/system/panel.log

chown -R hiddify-panel:hiddify-panel "$PANEL_DIR" >/dev/null 2>&1

# Runtime app.cfg lives under data/ so package updates cannot wipe secrets
mkdir -p "$(dirname "$APP_CFG")"
if [ ! -f "$APP_CFG" ]; then
    cp "$TEMPLATE_CFG" "$APP_CFG"
    # Rotate placeholder secret on first durable copy only
    if grep -qE '^SECRET_KEY=Pl3453Ch4ng3[[:space:]]*$' "$APP_CFG"; then
        sed -i "s/^SECRET_KEY=.*/SECRET_KEY=$(hiddify_random_password)/" "$APP_CFG"
    fi
fi
chmod 600 "$APP_CFG"

# set mysql password to flask app config
sed -i '/^SQLALCHEMY_DATABASE_URI/d' "$APP_CFG"
if [ -z "${SQLALCHEMY_DATABASE_URI}" ]; then
    if [ -z "${MYSQL_PASS}" ]; then
        MYSQL_PASS="$(get_mysql_password)"
    fi
    SQLALCHEMY_DATABASE_URI="mysql+mysqldb://hiddifypanel:$MYSQL_PASS@localhost/hiddifypanel?charset=utf8mb4"
fi
echo "SQLALCHEMY_DATABASE_URI ='$SQLALCHEMY_DATABASE_URI'" >>"$APP_CFG"

sed -i '/^REDIS_URI/d' "$APP_CFG"
if [ -z "${REDIS_URI_MAIN}" ]; then
    if [ -z "${REDIS_PASS}" ]; then
        REDIS_PASS="$(get_redis_password)"
    fi
    REDIS_URI_MAIN="redis://:${REDIS_PASS}@127.0.0.1:6379/0"
fi
echo "REDIS_URI_MAIN = '$REDIS_URI_MAIN'" >>"$APP_CFG"

chown hiddify-panel:hiddify-panel "$APP_CFG"

if [ -f "/opt/hiddify-manager/config.env" ]; then
    # systemctl restart --now mariadb
    # sleep 4

    hiddify-panel-cli import-config -c /opt/hiddify-manager/config.env

    # doesn't load virtual env
    #su hiddify-panel -c "hiddifypanel import-config -c $(pwd)/../config.env"

    if [ "$?" == 0 ]; then
        mv /opt/hiddify-manager/config.env /opt/hiddify-manager/config.env.old
        # echo "temporary disable removing config.env"
    fi
fi
systemctl stop hiddify-panel-background-tasks.service 2>/dev/null || true
hiddify-panel-cli init-db
systemctl start hiddify-panel.service
systemctl restart hiddify-panel-background-tasks.service
