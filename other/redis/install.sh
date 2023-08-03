


if [[ ! command -v redis-server ]];then
    sudo add-apt-repository -y universe
    # sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
    sudo apt install -y redis-server
fi
systemctl disable --now redis-server
ln -sf $(pwd)/hiddify-redis.service /etc/systemd/system/hiddify-redis.service
touch /opt/hiddify-config/log/system/redis-server.log
chown redis:redis /opt/hiddify-config/log/system/redis-server.log
chown redis:redis /opt/hiddify-config/other/redis
systemctl enable hiddify-redis
systemctl restart hiddify-redis
