source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/acme.sh/utils.sh
cd "$(dirname -- "$0")"

install_package socat
remove_package certbot

migrate_acme_durable_state

ACME_EMAIL="${ACME_EMAIL:-$(hiddify_random_password 4 | tr 'A-Z' 'a-z')@gmail.com}"

if [ ! -x "$ACME_LIB_DIR/acme.sh" ]; then
    install_acme_online "$ACME_EMAIL"
fi
if [ ! -x "$ACME_LIB_DIR/acme.sh" ]; then
    echo "Failed to install acme.sh into $ACME_LIB_DIR" >&2
    exit 1
fi

write_acme_env
"$ACME_LIB_DIR/acme.sh" --home "$ACME_LIB_DIR" --config-home "$ACME_CONFIG_HOME" --cert-home "$ACME_CERT_HOME" --upgrade
write_acme_env

if [ ! -x "$ACME_LIB_DIR/acme.sh" ]; then
    echo "acme.sh missing after upgrade: $ACME_LIB_DIR/acme.sh" >&2
    exit 1
fi

patch_acme_retry_overload
mkdir -p "$HIDDIFY_DATA/ssl"
set_files_in_folder_readable_to_hiddify_common_group "$HIDDIFY_DATA/ssl"
fix_acme_legacy_webroot_paths

# acme.sh --upgrade may recreate the old working dir; drop it.
if [ -d /opt/hiddify-manager/acme.sh ] && [ /opt/hiddify-manager/acme.sh != "$ACME_LIB_DIR" ]; then
    rm -rf /opt/hiddify-manager/acme.sh
fi

"$ACME_LIB_DIR/acme.sh" --home "$ACME_LIB_DIR" --config-home "$ACME_CONFIG_HOME" --cert-home "$ACME_CERT_HOME" --uninstall-cronjob
shopt -s expand_aliases
source "$ACME_ENV_FILE"
acme.sh --register-account -m "$ACME_EMAIL" --server letsencrypt || true
acme.sh --register-account -m "$ACME_EMAIL" --server zerossl || true
systemctl reload hiddify-haproxy
