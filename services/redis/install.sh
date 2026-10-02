source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/redis/utils.sh
cd "$(dirname -- "$0")"

if ! is_installed redis-server; then
    add-apt-repository -y universe
    install_package redis-server
fi

# STOP any running system redis first to avoid a window without a password
systemctl disable --now redis-server >/dev/null 2>&1 || true
pkill -9 redis-server >/dev/null 2>&1 || true

ensure_redis_data_dirs

if [ -f dump.rdb ] && [ ! -f "$HIDDIFY_DATA/redis/dump.rdb" ]; then
    mv dump.rdb "$HIDDIFY_DATA/redis/dump.rdb"
    chown redis:redis "$HIDDIFY_DATA/redis/dump.rdb"
fi

# Password + live conf: create once; --sync repairs requirepass (install-only changes)
ensure_redis_data --sync "$(pwd)/redis.conf"

ln -sf "$(pwd)/hiddify-redis.service" /etc/systemd/system/hiddify-redis.service >/dev/null 2>&1
systemctl daemon-reload >/dev/null 2>&1 || true
systemctl enable hiddify-redis

mkdir -p "$HIDDIFY_DATA/log/system"
touch "$HIDDIFY_DATA/log/system/redis-server.log"
chown redis:redis "$HIDDIFY_DATA/log/system/redis-server.log"
