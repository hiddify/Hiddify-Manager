source /opt/hiddify-manager/scripts/common/utils.sh
cd "$(dirname -- "$0")"
install_package socat
remove_package certbot

ACME_EMAIL="${ACME_EMAIL:-t@gmail.com}"
ACME_LIB="/opt/hiddify-manager/services/acme.sh/lib"
mkdir -p "$ACME_LIB"

# Official installer requires --home. Old LE_WORKING_DIR pointed at
# /opt/hiddify-manager/acme.sh/lib and --upgrade recreated that folder.
write_acme_env() {
    cat >"$ACME_LIB/acme.sh.env" <<EOF
export LE_WORKING_DIR="$ACME_LIB"
export LE_CONFIG_HOME="$ACME_LIB/data"
alias acme.sh="$ACME_LIB/acme.sh --config-home '$ACME_LIB/data'"
EOF
}

install_acme_online() {
    # Do not pipe args through get.acme.sh: it treats $1 as email=... so
    # `--home /path` becomes `----home` and install fails.
    curl -sL "https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh" |
        sh -s -- --install-online \
            --home "$ACME_LIB" \
            --config-home "$ACME_LIB/data" \
            --cert-home "$ACME_LIB/certs" \
            --nocron \
            --noprofile \
            --email "$ACME_EMAIL"
}

if [ ! -x "$ACME_LIB/acme.sh" ]; then
    install_acme_online
fi
if [ ! -x "$ACME_LIB/acme.sh" ]; then
    echo "Failed to install acme.sh into $ACME_LIB" >&2
    exit 1
fi

write_acme_env
"$ACME_LIB/acme.sh" --home "$ACME_LIB" --config-home "$ACME_LIB/data" --upgrade
write_acme_env

if [ ! -x "$ACME_LIB/acme.sh" ]; then
    echo "acme.sh missing after upgrade: $ACME_LIB/acme.sh" >&2
    exit 1
fi

if ! grep -q 'return 10; fi' "$ACME_LIB/acme.sh"; then
    sed -i 's|_sleep_overload_retry_sec=$_retryafter|_sleep_overload_retry_sec=$_retryafter; if [[ "$_retryafter" > 20 ]];then return 10; fi|g' "$ACME_LIB/acme.sh"
fi
mkdir -p /opt/hiddify-manager/data/ssl/
set_files_in_folder_readable_to_hiddify_common_group /opt/hiddify-manager/data/ssl

# Domain confs from v10 still name the old webroot.
find "$ACME_LIB" -type f -name '*.conf' -exec \
    sed -i 's|/opt/hiddify-manager/acme.sh/www/|/opt/hiddify-manager/data/services/acme.sh/www/|g' {} +

# acme.sh --upgrade may recreate the old working dir; drop it.
if [ -d /opt/hiddify-manager/acme.sh ] && [ /opt/hiddify-manager/acme.sh != "$ACME_LIB" ]; then
    rm -rf /opt/hiddify-manager/acme.sh
fi

"$ACME_LIB/acme.sh" --home "$ACME_LIB" --config-home "$ACME_LIB/data" --uninstall-cronjob
shopt -s expand_aliases
source "$ACME_LIB/acme.sh.env"
acme.sh --register-account -m "$ACME_EMAIL" --server letsencrypt || true
acme.sh --register-account -m "$ACME_EMAIL" --server zerossl || true
systemctl reload hiddify-haproxy
