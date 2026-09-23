# ACME install helpers — source after scripts/common/utils.sh

ACME_LIB_DIR="$HIDDIFY_SERVICES/acme.sh/lib"
ACME_DATA_DIR="$HIDDIFY_DATA/services/acme.sh"
ACME_CONFIG_HOME="$ACME_DATA_DIR/config"
ACME_CERT_HOME="$ACME_DATA_DIR/certs"
# Just path wiring (no secrets — those live under $ACME_CONFIG_HOME), but it
# must survive a reinstall of $ACME_LIB_DIR, so it's regenerated under data/.
ACME_ENV_FILE="$ACME_DATA_DIR/acme.sh.env"

function ensure_acme_data_dirs() {
    mkdir -p "$ACME_LIB_DIR" "$ACME_CONFIG_HOME" "$ACME_CERT_HOME" "$ACME_DATA_DIR/www"
}

function migrate_acme_durable_state() {
    local wrong_lib="$ACME_DATA_DIR/lib"

    ensure_acme_data_dirs

    if [ -L "$ACME_LIB_DIR" ]; then
        rm -f "$ACME_LIB_DIR"
        mkdir -p "$ACME_LIB_DIR"
    fi

    # Previous revision mistakenly put the whole lib under data/
    if [ -d "$wrong_lib" ] && [ ! -L "$wrong_lib" ]; then
        if [ ! -x "$ACME_LIB_DIR/acme.sh" ] && [ -x "$wrong_lib/acme.sh" ]; then
            find "$wrong_lib" -mindepth 1 -maxdepth 1 \
                ! -name data ! -name certs \
                -exec cp -a {} "$ACME_LIB_DIR/" \;
        fi
        if [ -d "$wrong_lib/data" ] && [ -z "$(ls -A "$ACME_CONFIG_HOME" 2>/dev/null)" ]; then
            cp -a "$wrong_lib/data/." "$ACME_CONFIG_HOME/"
        fi
        if [ -d "$wrong_lib/certs" ] && [ -z "$(ls -A "$ACME_CERT_HOME" 2>/dev/null)" ]; then
            cp -a "$wrong_lib/certs/." "$ACME_CERT_HOME/"
        fi
        rm -rf "$wrong_lib"
    fi

    if [ -d "$ACME_LIB_DIR/data" ] && [ ! -L "$ACME_LIB_DIR/data" ]; then
        if [ -z "$(ls -A "$ACME_CONFIG_HOME" 2>/dev/null)" ]; then
            cp -a "$ACME_LIB_DIR/data/." "$ACME_CONFIG_HOME/"
        fi
        rm -rf "$ACME_LIB_DIR/data"
    fi
    if [ -d "$ACME_LIB_DIR/certs" ] && [ ! -L "$ACME_LIB_DIR/certs" ]; then
        if [ -z "$(ls -A "$ACME_CERT_HOME" 2>/dev/null)" ]; then
            cp -a "$ACME_LIB_DIR/certs/." "$ACME_CERT_HOME/"
        fi
        rm -rf "$ACME_LIB_DIR/certs"
    fi
}

function write_acme_env() {
    cat >"$ACME_ENV_FILE" <<EOF
export LE_WORKING_DIR="$ACME_LIB_DIR"
export LE_CONFIG_HOME="$ACME_CONFIG_HOME"
export LE_CERT_HOME="$ACME_CERT_HOME"
alias acme.sh="$ACME_LIB_DIR/acme.sh --config-home '$ACME_CONFIG_HOME' --cert-home '$ACME_CERT_HOME'"
EOF
}

function install_acme_online() {
    local email="${1:?}"
    # Do not pipe args through get.acme.sh: it treats $1 as email=... so
    # `--home /path` becomes `----home` and install fails.
    curl -sL "https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh" |
        sh -s -- --install-online \
            --home "$ACME_LIB_DIR" \
            --config-home "$ACME_CONFIG_HOME" \
            --cert-home "$ACME_CERT_HOME" \
            --nocron \
            --noprofile \
            --email "$email"
}

function patch_acme_retry_overload() {
    local acme_sh="$ACME_LIB_DIR/acme.sh"
    if [ -x "$acme_sh" ] && ! grep -q 'return 10; fi' "$acme_sh"; then
        sed -i 's|_sleep_overload_retry_sec=$_retryafter|_sleep_overload_retry_sec=$_retryafter; if [[ "$_retryafter" > 20 ]];then return 10; fi|g' "$acme_sh"
    fi
}

function fix_acme_legacy_webroot_paths() {
    find "$ACME_CONFIG_HOME" "$ACME_CERT_HOME" -type f -name '*.conf' 2>/dev/null -exec \
        sed -i 's|/opt/hiddify-manager/acme.sh/www/|/opt/hiddify-manager/data/services/acme.sh/www/|g' {} +
}

# Import TLS certificates from data/ssl/ into tls_store: all domains, or just "$1".
function sync_tls_store() {
    local domain="$1"
    local query=""
    [ -n "$domain" ] && query="?domain=$(jq -rn --arg d "$domain" '$d|@uri')"
    if hiddify-http-api "admin/sync-tls-store/$query" >/dev/null; then
        return 0
    fi

    local flags=()
    [ -n "$domain" ] && flags+=(-d "$domain")
    hiddify-panel-cli sync-tls-store "${flags[@]}"
}
