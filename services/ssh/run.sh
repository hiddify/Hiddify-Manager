

#sed -i "s/:2222/:$ssh_server_port/g" .env
ln -sf $(pwd)/hiddify-ssh-liberty-bridge.service /etc/systemd/system/hiddify-ssh-liberty-bridge.service

chown -R liberty-bridge host_key
sed -i '/REDIS_URL/d' .env

if [ -z "${REDIS_URI_SSH}" ]; then
    REDIS_PASS=$(grep '^requirepass' "../redis/redis.conf" | awk '{print $2}')
    REDIS_URI_SSH="redis://:${REDIS_PASS}@127.0.0.1:6379/1"
fi

echo "REDIS_URL='$REDIS_URI_SSH'" >>.env

chmod 600 .env*

systemctl enable hiddify-ssh-liberty-bridge
systemctl restart hiddify-ssh-liberty-bridge