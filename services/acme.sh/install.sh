source /opt/hiddify-manager/scripts/common/utils.sh
install_package socat
remove_package certbot

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

if ! is_installed "$ACME_LIB/acme.sh"; then
    curl -s -L https://get.acme.sh | sh -s -- --home "$ACME_LIB" \
        --config-home "$ACME_LIB/data" \
        --cert-home "$ACME_LIB/certs" --nocron
fi
write_acme_env
./lib/acme.sh --home "$ACME_LIB" --config-home "$ACME_LIB/data" --upgrade
write_acme_env

if ! grep -q 'return 10; fi' "./lib/acme.sh"; then
    sed -i 's|_sleep_overload_retry_sec=$_retryafter|_sleep_overload_retry_sec=$_retryafter; if [[ "$_retryafter" > 20 ]];then return 10; fi|g' lib/acme.sh
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

./lib/acme.sh --home "$ACME_LIB" --config-home "$ACME_LIB/data" --uninstall-cronjob
shopt -s expand_aliases
source ./lib/acme.sh.env
acme.sh --register-account -m my@example.com
systemctl reload hiddify-haproxy
