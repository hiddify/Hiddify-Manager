source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/mysql/utils.sh
source /opt/hiddify-manager/services/redis/utils.sh
activate_python_venv

mkdir -p "$HIDDIFY_DATA/hiddify-panel" "$HIDDIFY_DATA/log"

PANEL_DIR="/opt/hiddify-manager/services/panel"
APP_CFG="$HIDDIFY_PANEL_CFG_PATH"
TEMPLATE_CFG="$PANEL_DIR/app.cfg"

echo -n "" >> /opt/hiddify-manager/data/log/panel.log
chown hiddify-panel /opt/hiddify-manager/data/log/panel.log

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

# Read one KEY='value' line from app.cfg (this script writes single-quoted values; the
# space before '=' on the URI lines must also match). Empty output when absent.
function appcfg_value() {
    sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*'\\([^']*\\)'.*/\\1/p" "$APP_CFG" | head -1
}

# set mysql password to flask app config
#
# Connection URI resolution order:
# 1. SQLALCHEMY_DATABASE_URI / REDIS_URI_MAIN env vars (docker.env in Docker
#    mode, or exported in the shell that runs install.sh / updates on a server):
#    an explicit value always wins.
# 2. A URI persisted by a previous run together with the HIDDIFY_EXTERNAL_* marker
#    (a configured external database/Redis survives updates even when the env
#    vars are no longer exported; the markers get rewritten below).
# 3. The built-in local MariaDB / Redis with their durable generated passwords.
# The env vars must never be re-exported later to keep the external URIs: scripts
# (is_panel_db_external / is_panel_redis_external in scripts/common/utils.sh) read
# both the env and these markers, so e.g. scripts/install.sh keeps skipping the
# local MySQL/Redis install after updates.
if grep -q '^HIDDIFY_EXTERNAL_DB=True' "$APP_CFG" 2>/dev/null; then DB_IS_EXTERNAL=1; else DB_IS_EXTERNAL=0; fi
if grep -q '^HIDDIFY_EXTERNAL_REDIS=True' "$APP_CFG" 2>/dev/null; then REDIS_IS_EXTERNAL=1; else REDIS_IS_EXTERNAL=0; fi

SQLALCHEMY_DB_URI="${SQLALCHEMY_DATABASE_URI:-}"
REDIS_MAIN_URI="${REDIS_URI_MAIN:-}"
if [ "$DB_IS_EXTERNAL" = "1" ] && [ -z "$SQLALCHEMY_DB_URI" ]; then
    SQLALCHEMY_DB_URI="$(appcfg_value SQLALCHEMY_DATABASE_URI)"
fi
if [ "$REDIS_IS_EXTERNAL" = "1" ] && [ -z "$REDIS_MAIN_URI" ]; then
    REDIS_MAIN_URI="$(appcfg_value REDIS_URI_MAIN)"
fi

# Corrupted state: an external marker without any URI (the URI line was removed
# from app.cfg by hand). The installer already skips the local MySQL/Redis in
# that case, so failing loudly beats silently booting against a database that
# does not exist here.
if [ "$DB_IS_EXTERNAL" = "1" ] && [ -z "$SQLALCHEMY_DB_URI" ]; then
    error "HIDDIFY_EXTERNAL_DB=True is set in $APP_CFG, but no SQLALCHEMY_DATABASE_URI is exported and none is persisted in $APP_CFG. Add the URI line back or remove the marker line, then re-run the install."
    exit 1
fi
if [ "$REDIS_IS_EXTERNAL" = "1" ] && [ -z "$REDIS_MAIN_URI" ]; then
    error "HIDDIFY_EXTERNAL_REDIS=True is set in $APP_CFG, but no REDIS_URI_MAIN is exported and none is persisted in $APP_CFG. Add the URI line back or remove the marker line, then re-run the install."
    exit 1
fi

if [ -z "$SQLALCHEMY_DB_URI" ]; then
    if [ -z "${MYSQL_PASS}" ]; then
        MYSQL_PASS="$(get_mysql_password)"
    fi
    SQLALCHEMY_DB_URI="mysql+mysqldb://hiddifypanel:$MYSQL_PASS@localhost/hiddifypanel?charset=utf8mb4"
fi
if [ -z "$REDIS_MAIN_URI" ]; then
    if [ -z "${REDIS_PASS}" ]; then
        REDIS_PASS="$(get_redis_password)"
    fi
    REDIS_MAIN_URI="redis://:${REDIS_PASS}@127.0.0.1:6379/0"
fi

sed -i '/^SQLALCHEMY_DATABASE_URI/d;/^HIDDIFY_EXTERNAL_DB=/d;/^REDIS_URI/d;/^HIDDIFY_EXTERNAL_REDIS=/d' "$APP_CFG"
echo "SQLALCHEMY_DATABASE_URI ='$SQLALCHEMY_DB_URI'" >>"$APP_CFG"
echo "REDIS_URI_MAIN = '$REDIS_MAIN_URI'" >>"$APP_CFG"
if [ -n "${SQLALCHEMY_DATABASE_URI:-}" ] || [ "$DB_IS_EXTERNAL" = "1" ]; then
    echo "HIDDIFY_EXTERNAL_DB=True" >>"$APP_CFG"
fi
if [ -n "${REDIS_URI_MAIN:-}" ] || [ "$REDIS_IS_EXTERNAL" = "1" ]; then
    echo "HIDDIFY_EXTERNAL_REDIS=True" >>"$APP_CFG"
fi

chown hiddify-panel:hiddify-panel "$APP_CFG"

if [ -f "/opt/hiddify-manager/config.env" ]; then
    # systemctl restart --now hiddify-mysql
    # sleep 4

    hiddify-panel-cli import-config -c /opt/hiddify-manager/config.env

    # doesn't load virtual env
    #su hiddify-panel -c "hiddifypanel import-config -c $(pwd)/../config.env"

    if [ "$?" == 0 ]; then
        mv /opt/hiddify-manager/config.env /opt/hiddify-manager/config.env.old
        # echo "temporary disable removing config.env"
    fi
fi
hiddify-panel-cli init-db
systemctl start hiddify-panel.service
