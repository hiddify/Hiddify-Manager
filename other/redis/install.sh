source /opt/hiddify-server/common/utils.sh
if ! is_installed redis-server; then
    add-apt-repository -y universe
    install_package redis-server
fi
systemctl disable --now redis-server >/dev/null 2>&1
ln -sf $(pwd)/hiddify-redis.service /etc/systemd/system/hiddify-redis.service >/dev/null 2>&1
touch /opt/hiddify-server/log/system/redis-server.log
chown redis:redis /opt/hiddify-server/log/system/redis-server.log
chown redis:redis /opt/hiddify-server/other/redis
systemctl enable hiddify-redis
systemctl restart hiddify-redis
