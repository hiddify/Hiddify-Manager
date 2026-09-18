source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/redis/utils.sh
cd "$(dirname -- "$0")"

SSH_DATA="$HIDDIFY_DATA/services/ssh"
mkdir -p "$SSH_DATA/host_key" "$SSH_DATA/ssh-users"

# Migrate legacy in-tree permanent files into data/
if [ -d host_key ] && [ ! -L host_key ]; then
    if [ -z "$(ls -A "$SSH_DATA/host_key" 2>/dev/null)" ] && [ -n "$(ls -A host_key 2>/dev/null)" ]; then
        cp -a host_key/. "$SSH_DATA/host_key/"
    fi
    rm -rf host_key
fi
if [ -d ssh-users ] && [ ! -L ssh-users ]; then
    if [ -z "$(ls -A "$SSH_DATA/ssh-users" 2>/dev/null)" ] && [ -n "$(ls -A ssh-users 2>/dev/null)" ]; then
        cp -a ssh-users/. "$SSH_DATA/ssh-users/"
    fi
    rm -rf ssh-users
fi
if [ -f .env ] && [ ! -L .env ]; then
    if [ ! -f "$SSH_DATA/.env" ]; then
        cp -a .env "$SSH_DATA/.env"
    fi
    rm -f .env
fi

ln -sfn "$SSH_DATA/host_key" host_key
ln -sfn "$SSH_DATA/ssh-users" ssh-users
ln -sfn "$SSH_DATA/.env" .env

#sed -i "s/:2222/:$ssh_server_port/g" .env
ln -sf "$(pwd)/hiddify-ssh-liberty-bridge.service" /etc/systemd/system/hiddify-ssh-liberty-bridge.service

chown -R liberty-bridge "$SSH_DATA/host_key"
touch "$SSH_DATA/.env"
sed -i '/REDIS_URL/d' "$SSH_DATA/.env"

if [ -z "${REDIS_URI_MAIN}" ]; then
    if [ -z "${REDIS_PASS}" ]; then
        REDIS_PASS="$(get_redis_password)"
    fi
    REDIS_URI_MAIN="redis://:${REDIS_PASS}@127.0.0.1:6379/1"
fi

echo "REDIS_URL='$REDIS_URI_MAIN'" >>"$SSH_DATA/.env"

chmod 600 "$SSH_DATA/.env"* 2>/dev/null || chmod 600 "$SSH_DATA/.env"
chown liberty-bridge "$SSH_DATA/.env"* 2>/dev/null || chown liberty-bridge "$SSH_DATA/.env"

systemctl enable hiddify-ssh-liberty-bridge
systemctl restart hiddify-ssh-liberty-bridge
