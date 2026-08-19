source /opt/hiddify-manager/scripts/common/utils.sh
if ! is_installed redis-server; then
    add-apt-repository -y universe
    install_package redis-server
fi

# STOP any running system redis first to avoid a window without a password
systemctl disable --now redis-server >/dev/null 2>&1 || true
pkill -9 redis-server >/dev/null 2>&1 || true

chown -R redis:redis .
chmod 600 redis.conf
mkdir -p /opt/hiddify-manager/data/redis
chown redis:redis /opt/hiddify-manager/data/redis
if [ -f dump.rdb ] && [ ! -f /opt/hiddify-manager/data/redis/dump.rdb ]; then
    mv dump.rdb /opt/hiddify-manager/data/redis/dump.rdb
    chown redis:redis /opt/hiddify-manager/data/redis/dump.rdb
fi

# Ensure a password exists in repo config before starting any service
if ! grep -q "^requirepass" "redis.conf"; then
    # Generate a random password
    random_password=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c49; echo)
    # Add requirepass with the generated password to redis.conf
    echo "requirepass $random_password" >>redis.conf
fi

# Wire up and start the managed service using the repo config
ln -sf $(pwd)/hiddify-redis.service /etc/systemd/system/hiddify-redis.service >/dev/null 2>&1
systemctl enable --now hiddify-redis

# Ensure logging path exists/owned
touch /opt/hiddify-manager/data/log/system/redis-server.log
chown redis:redis /opt/hiddify-manager/data/log/system/redis-server.log



# systemctl reload hiddify-redis
