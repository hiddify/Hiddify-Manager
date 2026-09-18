source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/redis/utils.sh
cd "$(dirname -- "$0")"

# Apply-only path skips install.sh; ensure durable conf/password exist (no regen if present)
ensure_redis_data "$(pwd)/redis.conf"
systemctl start hiddify-redis
