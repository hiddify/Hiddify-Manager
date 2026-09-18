# Redis helpers — source after scripts/common/utils.sh

HIDDIFY_REDIS_DATA="$HIDDIFY_DATA/redis"
HIDDIFY_REDIS_PASS_FILE="$HIDDIFY_REDIS_DATA/redis_pass"
HIDDIFY_REDIS_LIVE_CONF="$HIDDIFY_REDIS_DATA/redis.conf"

function ensure_redis_data_dirs() {
    mkdir -p "$HIDDIFY_REDIS_DATA"
    chown redis:redis "$HIDDIFY_REDIS_DATA" 2>/dev/null || true
}

function redis_pass_from_conf() {
    local conf="$1"
    local pass=""
    [ -f "$conf" ] || return 1
    pass="$(grep '^requirepass ' "$conf" 2>/dev/null | awk '{print $2}' | tail -n1 || true)"
    [ -n "$pass" ] || return 1
    printf '%s\n' "$pass"
}

function get_redis_password() {
    cat "$HIDDIFY_REDIS_PASS_FILE"
}

# Idempotent Redis durable state under data/.
# - Password file: created once (migrate from conf requirepass, else generate)
# - Live conf: copied from package template once; requirepass injected only when
#   missing or when --sync is passed (install-time repairs / password changes)
function ensure_redis_data() {
    ensure_redis_data_dirs
    local force_sync=0
    if [ "${1:-}" = "--sync" ]; then
        force_sync=1
        shift
    fi
    local template="${1:-$HIDDIFY_SERVICES/redis/redis.conf}"
    local pass

    if [ ! -f "$HIDDIFY_REDIS_PASS_FILE" ]; then
        pass="$(redis_pass_from_conf "$HIDDIFY_REDIS_LIVE_CONF" || redis_pass_from_conf "$template" || true)"
        [ -n "$pass" ] || pass="$(hiddify_random_password)"
        echo "$pass" >"$HIDDIFY_REDIS_PASS_FILE"
        chmod 600 "$HIDDIFY_REDIS_PASS_FILE"
    fi

    # Keep packaged template free of secrets
    sed -i '/^requirepass /d' "$template" 2>/dev/null || true

    if [ ! -f "$HIDDIFY_REDIS_LIVE_CONF" ]; then
        cp "$template" "$HIDDIFY_REDIS_LIVE_CONF"
        force_sync=1
    fi

    if [ "$force_sync" = 1 ] || ! grep -q '^requirepass ' "$HIDDIFY_REDIS_LIVE_CONF"; then
        sed -i '/^requirepass /d' "$HIDDIFY_REDIS_LIVE_CONF"
        echo "requirepass $(cat "$HIDDIFY_REDIS_PASS_FILE")" >>"$HIDDIFY_REDIS_LIVE_CONF"
    fi
    chmod 600 "$HIDDIFY_REDIS_LIVE_CONF" "$HIDDIFY_REDIS_PASS_FILE"
    chown redis:redis "$HIDDIFY_REDIS_LIVE_CONF" "$HIDDIFY_REDIS_PASS_FILE" 2>/dev/null || true
}
