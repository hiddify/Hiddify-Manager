source /opt/hiddify-manager/common/utils.sh
if ! is_installed redis-server; then
    add-apt-repository -y universe
    install_package redis-server
fi
systemctl disable --now redis-server >/dev/null 2>&1
pkill -9 redis-server
ln -sf $(pwd)/hiddify-redis.service /etc/systemd/system/hiddify-redis.service >/dev/null 2>&1
touch /opt/hiddify-manager/log/system/redis-server.log
chown redis:redis /opt/hiddify-manager/log/system/redis-server.log
chown redis:redis /opt/hiddify-manager/other/redis
systemctl enable hiddify-redis
# systemctl reload hiddify-redis
