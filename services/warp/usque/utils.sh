# WARP usque (MASQUE) helpers — source after scripts/common/utils.sh
source /opt/hiddify-manager/services/warp/utils.sh

# Permanent account file (survives a release unzip of services/). Symlinked into svc_dir for convenience.
function warp_usque_data_dir() {
    echo "$HIDDIFY_DATA/services/warp/usque"
}

function warp_usque_config() {
    echo "$(warp_usque_data_dir)/config.json"
}

function warp_usque_real_test() {
    # curl 8.18 refuses ".5" ("expected a proper numerical parameter")
    curl -s --interface warp --connect-timeout 3 --max-time 8 "http://ip-api.com?fields=message,country,org,query"
    local error=$?
    if [ "$error" = 0 ]; then
        success "WARP is WORKING!"
    else
        warning "WARP is not working!"
    fi
    return $error
}

function stop_other_warp_backends() {
    # Only one process may own the "warp" interface.
    systemctl stop --now wg-quick@warp >/dev/null 2>&1 || true
    systemctl disable wg-quick@warp >/dev/null 2>&1 || true
    ip link show warp >/dev/null 2>&1 && ip link delete warp >/dev/null 2>&1 || true
}

function install_warp_usque_unit() {
    local svc_dir="${1:-.}"
    mkdir -p /opt/hiddify-manager/data/log/system
    ln -sfn "$(realpath "$svc_dir/hiddify-warp.service")" /etc/systemd/system/hiddify-warp.service
    systemctl daemon-reload
    systemctl enable hiddify-warp.service
}

function warp_usque_exec() {
    local svc_dir="${1:-.}"
    shift
    local cfg
    cfg=$(warp_usque_config)
    (cd "$svc_dir" && ./usque -c "$cfg" "$@")
}

function apply_warp_usque_plus() {
    local svc_dir="${1:-.}"
    local key
    # Set WARP_USQUE_SKIP_PLUS=1 for a last-chance connect without a bad license key.
    [ "${WARP_USQUE_SKIP_PLUS:-}" = 1 ] && return 0
    key=$(hconfig warp_plus_code 2>/dev/null || true)
    key=${key//[[:space:]]/}
    [ -z "$key" ] && return 0
    if warp_usque_exec "$svc_dir" account set "$key"; then
        success "WARP+ license applied"
        return 0
    fi
    warning "WARP+ license failed; continuing with the free account"
    return 1
}

function reset_warp_usque_account() {
    local svc_dir="${1:-.}"
    local data cfg
    data=$(warp_usque_data_dir)
    cfg=$(warp_usque_config)
    echo "Resetting WARP (usque) account..."
    mkdir -p "$data"
    if [ -e "$cfg" ]; then
        mv -f "$cfg" "$data/config.json.backup" 2>/dev/null || true
    elif [ -e "$svc_dir/config.json" ] && [ ! -L "$svc_dir/config.json" ]; then
        # Leftover from before configs lived in data/: archive it.
        mv -f "$svc_dir/config.json" "$data/config.json.backup" 2>/dev/null || true
    fi
    rm -f "$svc_dir/config.json" "$cfg"
    local rc=0
    (cd "$svc_dir" && ./usque register -a -m hiddify -n "$(hostname)" -c "$cfg") || rc=$?
    if [ "$rc" != 0 ]; then
        [ -e "$data/config.json.backup" ] && cp -f "$data/config.json.backup" "$cfg"
        ensure_warp_data_links usque "$svc_dir"
        return $rc
    fi
    ensure_warp_data_links usque "$svc_dir"
    apply_warp_usque_plus "$svc_dir" || true
}

function _restart_warp_usque() {
    stop_other_warp_backends
    systemctl restart hiddify-warp.service
}

function check_warp_usque_connection() {
    local svc_dir="${1:-.}"
    local cfg
    cfg=$(warp_usque_config)
    echo "Checking WARP (usque)..."
    ensure_warp_data_links usque "$svc_dir"
    if ! [ -f "$cfg" ]; then
        reset_warp_usque_account "$svc_dir" || return $?
    fi
    apply_warp_usque_plus "$svc_dir" || true
    if ! warp_usque_exec "$svc_dir" enroll >/dev/null 2>&1; then
        warning "WARP enroll failed; registering a new account"
        reset_warp_usque_account "$svc_dir" || return $?
        warp_usque_exec "$svc_dir" enroll >/dev/null 2>&1 || return $?
    fi
    ensure_warp_data_links usque "$svc_dir"
    install_warp_usque_unit "$svc_dir"
    _restart_warp_usque
    echo "Starting WARP... checking real connectivity"
    sleep 3
    if warp_usque_real_test; then
        return 0
    fi
    sleep 3
    echo "Checking real connectivity again"
    if warp_usque_real_test; then
        return 0
    fi
    warning "WARP connectivity failed; registering a new account"
    reset_warp_usque_account "$svc_dir" || return $?
    warp_usque_exec "$svc_dir" enroll >/dev/null 2>&1 || return $?
    ensure_warp_data_links usque "$svc_dir"
    _restart_warp_usque
    sleep 3
    warp_usque_real_test || return $?
}
