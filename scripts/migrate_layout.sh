#!/bin/bash
# After unzip -o of a new release over /opt/hiddify-manager, leftover v10
# folders remain. If singbox/ still exists, this is an old layout: keep
# MySQL/Redis passwords and move leftover folders to old/.
# If singbox/ is gone, this is a clean install or an already-migrated tree.

set -euo pipefail

HIDDIFY_DIR="${HIDDIFY_DIR:-/opt/hiddify-manager}"
cd "$HIDDIFY_DIR"

SERVICES="$HIDDIFY_DIR/services"
SCRIPTS="$HIDDIFY_DIR/scripts"
DATA="$HIDDIFY_DIR/data"
OLD="$HIDDIFY_DIR/old"

log() { echo "[migrate-layout] $*"; }

# Note: $DATA/mysql/db (the actual datadir) is intentionally not created here —
# mysql/utils.sh's migrate_mysql_datadir needs that path absent or already
# populated to do its atomic mv; see that file for details.
mkdir -p "$SERVICES/mysql" "$SERVICES/redis" \
    "$DATA/ssl" "$DATA/log/system" "$DATA/mysql" "$DATA/redis" \
    "$DATA/hiddify-panel" "$HIDDIFY_DIR/generated"

install_hiddify_cli() {
    chmod +x "$SCRIPTS/hiddify" 2>/dev/null || true
    if [ -f "$SCRIPTS/hiddify" ]; then
        ln -sf "$SCRIPTS/hiddify" /usr/bin/hiddify
        mkdir -p /etc/bash_completion.d /etc/profile.d
        if [ -f "$SCRIPTS/hiddify-completion.bash" ]; then
            ln -sf "$SCRIPTS/hiddify-completion.bash" /etc/bash_completion.d/hiddify
            if [ -f "$HOME/.bashrc" ] && ! grep -qF 'hiddify-completion.bash' "$HOME/.bashrc"; then
                echo '[ -f /opt/hiddify-manager/scripts/hiddify-completion.bash ] && . /opt/hiddify-manager/scripts/hiddify-completion.bash' >>"$HOME/.bashrc"
            fi
        fi
        if [ -f "$SCRIPTS/hiddify-profile.sh" ]; then
            ln -sf "$SCRIPTS/hiddify-profile.sh" /etc/profile.d/hiddify.sh
        fi
        log "installed hiddify CLI -> /usr/bin/hiddify"
    fi
}

rename_singbox_unit() {
    if [ -e /etc/systemd/system/hiddify-singbox.service ]; then
        log "replacing hiddify-singbox.service with hiddify-core.service"
        systemctl disable --now hiddify-singbox.service 2>/dev/null || true
        rm -f /etc/systemd/system/hiddify-singbox.service
    fi
    if [ -f "$SERVICES/hiddify-core/hiddify-core.service" ]; then
        ln -sf "$SERVICES/hiddify-core/hiddify-core.service" /etc/systemd/system/hiddify-core.service
        systemctl daemon-reload 2>/dev/null || true
        systemctl enable hiddify-core.service 2>/dev/null || true
    fi
}

move_to_old() {
    local path="$1"
    local name
    name="$(basename "$path")"
    if [ -L "$path" ]; then
        log "removing leftover symlink $path"
        rm -f "$path"
        return 0
    fi
    if [ ! -e "$path" ]; then
        return 0
    fi
    mkdir -p "$OLD"
    local dest="$OLD/$name"
    if [ -e "$dest" ]; then
        dest="$OLD/${name}.$(date +%Y%m%d%H%M%S)"
    fi
    log "mv $path -> $dest"
    mv "$path" "$dest"
}

# Clean install or already migrated: no leftover singbox/ directory.
if [ ! -d "$HIDDIFY_DIR/singbox" ] || [ -L "$HIDDIFY_DIR/singbox" ]; then
    if [ -L "$HIDDIFY_DIR/singbox" ]; then
        log "removing leftover singbox symlink"
        rm -f "$HIDDIFY_DIR/singbox"
    fi
    # acme.sh --upgrade can recreate the old working dir after migration.
    move_to_old "$HIDDIFY_DIR/acme.sh"
    
    rename_singbox_unit
    install_hiddify_cli
    exit 0
fi

log "singbox/ found; migrating leftover old-layout folders to old/"

# Reuse service helpers when available (same create-once paths under data/)
if [ -f "$SCRIPTS/common/utils.sh" ]; then
    # shellcheck source=/dev/null
    source "$SCRIPTS/common/utils.sh"
fi
if [ -f "$SERVICES/mysql/utils.sh" ]; then
    # shellcheck source=/dev/null
    source "$SERVICES/mysql/utils.sh"
fi
if [ -f "$SERVICES/redis/utils.sh" ]; then
    # shellcheck source=/dev/null
    source "$SERVICES/redis/utils.sh"
fi

preserve_mysql_pass() {
    local dest="${HIDDIFY_MYSQL_PASS_FILE:-${HIDDIFY_DATA:-$DATA}/mysql/mysql_pass}"
    local src
    mkdir -p "$(dirname "$dest")"
    if [ -f "$dest" ]; then
        return 0
    fi
    for src in \
        "$SERVICES/mysql/mysql_pass" \
        "$HIDDIFY_DIR/other/mysql/mysql_pass" \
        "$HIDDIFY_DIR/mysql/mysql_pass"
    do
        if [ -f "$src" ]; then
            cp -a "$src" "$dest"
            chmod 600 "$dest"
            log "kept MySQL password from $src -> $dest"
            return 0
        fi
    done
}

preserve_redis_pass() {
    local dest_pass="${HIDDIFY_REDIS_PASS_FILE:-${HIDDIFY_DATA:-$DATA}/redis/redis_pass}"
    local src pass=""
    mkdir -p "$(dirname "$dest_pass")"
    if [ -f "$dest_pass" ]; then
        return 0
    fi
    for src in \
        "${HIDDIFY_REDIS_LIVE_CONF:-${HIDDIFY_DATA:-$DATA}/redis/redis.conf}" \
        "$SERVICES/redis/redis.conf" \
        "$HIDDIFY_DIR/other/redis/redis.conf" \
        "$HIDDIFY_DIR/redis/redis.conf"
    do
        if type redis_pass_from_conf >/dev/null 2>&1; then
            pass="$(redis_pass_from_conf "$src" || true)"
        else
            pass="$(grep '^requirepass ' "$src" 2>/dev/null | awk '{print $2}' | tail -n1 || true)"
        fi
        if [ -n "$pass" ]; then
            log "kept Redis password from $src"
            break
        fi
    done
    [ -n "$pass" ] || return 0
    echo "$pass" >"$dest_pass"
    chmod 600 "$dest_pass"
    if type ensure_redis_data >/dev/null 2>&1; then
        ensure_redis_data --sync "$SERVICES/redis/redis.conf"
    fi
}

preserve_mysql_pass
preserve_redis_pass

for name in nginx haproxy singbox xray hiddify-panel acme.sh other ssl log mysql redis; do
    move_to_old "$HIDDIFY_DIR/$name"
done

# v10 common/ is leftover; keep only the packaged download.sh shim if present.
if [ -d "$HIDDIFY_DIR/common" ] && [ ! -L "$HIDDIFY_DIR/common" ]; then
    if [ -f "$HIDDIFY_DIR/common/utils.sh" ] || [ -f "$HIDDIFY_DIR/common/install.sh" ]; then
        shim=""
        if [ -f "$HIDDIFY_DIR/common/download.sh" ]; then
            shim="$(mktemp)"
            cp "$HIDDIFY_DIR/common/download.sh" "$shim"
        fi
        move_to_old "$HIDDIFY_DIR/common"
        if [ -n "$shim" ]; then
            mkdir -p "$HIDDIFY_DIR/common"
            mv "$shim" "$HIDDIFY_DIR/common/download.sh"
        fi
    fi
fi

for f in apply_configs.sh docker-init.sh install.sh menu.sh restart.sh status.sh uninstall.sh update.sh current.json; do
    move_to_old "$HIDDIFY_DIR/$f"
done

rename_singbox_unit
install_hiddify_cli


