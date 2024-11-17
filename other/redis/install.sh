source /opt/hiddify-manager/common/utils.sh
if ! is_installed redis-server; then
    add-apt-repository -y universe
    install_package redis-server
fi
ln -sf $(pwd)/hiddify-redis.service /etc/systemd/system/hiddify-redis.service >/dev/null 2>&1
systemctl enable hiddify-redis
touch /opt/hiddify-manager/log/system/redis-server.log
chown redis:redis /opt/hiddify-manager/log/system/redis-server.log
chown -R redis:redis .
chmod 600 redis.conf

if ! grep -q "^requirepass" "redis.conf"; then
    # Generate a random password
    random_password=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c49; echo)
    # Add requirepass with the generated password to redis.conf
    echo "requirepass $random_password" >>redis.conf   
    systemctl disable --now redis-server >/dev/null 2>&1
    pkill -9 redis-server
    systemctl restart hiddify-redis
fi



# systemctl reload hiddify-redis
