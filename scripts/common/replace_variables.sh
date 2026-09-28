cd $(dirname -- "$0")
source ./utils.sh
activate_python_venv
ensure_hiddify_data_dirs

if ! is_valid_current_json /opt/hiddify-manager/data/current.json; then
    error "Invalid /opt/hiddify-manager/data/current.json; not applying configs"
    exit 1
fi
domains=$(jq -r '.domains[] | .domain' /opt/hiddify-manager/data/current.json | tr '\n' ' ')

# Remove certificates only for domains deleted from the panel since the last
# apply. Certificates the panel never listed (manual, wildcard, …) are kept.
known_domains_file=/opt/hiddify-manager/data/services/acme.sh/panel_domains
if [ -z "${domains// /}" ]; then
    warning "No domains in current.json; keeping existing certificates"
else
    if [ -f "$known_domains_file" ]; then
        while read -r d; do
            [ -n "$d" ] || continue
            if [[ ! " ${domains} " =~ " ${d} " ]]; then
                echo "Domain $d was removed; deleting its certificate"
                rm -f "/opt/hiddify-manager/data/ssl/$d.crt" "/opt/hiddify-manager/data/ssl/$d.crt.key"
            fi
        done <"$known_domains_file"
    fi
    mkdir -p "$(dirname "$known_domains_file")"
    printf '%s\n' $domains >"$known_domains_file"
fi

# we need at least one ssl certificate to be able to run haproxy
for d in $domains; do
    (bash /opt/hiddify-manager/services/acme.sh/generate_self_signed_cert.sh $d >/dev/null 2>&1)
done

dump_server_configs || {
    echo "Failed to dump server configs into $HIDDIFY_GENERATED" >&2
    exit 1
}

if getent group hiddify-common >/dev/null 2>&1; then
    for f in "${HIDDIFY_SERVER_CONFIG_FILES[@]}"; do
        if [ -f "$HIDDIFY_GENERATED/$f" ]; then
            chmod 640 "$HIDDIFY_GENERATED/$f"
            chown hiddify-panel:hiddify-common "$HIDDIFY_GENERATED/$f"
        fi
    done
    if [ -d "$HIDDIFY_GENERATED/include" ]; then
        chown -R hiddify-panel:hiddify-common "$HIDDIFY_GENERATED/include"
        find "$HIDDIFY_GENERATED/include" -type d -exec chmod 775 {} \;
        find "$HIDDIFY_GENERATED/include" -type f -exec chmod 640 {} \;
    fi
fi

# Remaining .j2 templates (run.sh, firewall, ssh, …) — not dump-server-configs output.
/opt/hiddify-manager/scripts/common/jinja.py $MODE
