cd $(dirname -- "$0")
source ./utils.sh
activate_python_venv
ensure_hiddify_data_dirs

domains=$(cat /opt/hiddify-manager/data/current.json | jq -r '.domains[] | .domain' | tr '\n' ' ')


# Loop over the .crt files
for f in /opt/hiddify-manager/data/ssl/*.crt; do
    # Get the basename without the .crt extension
    d=$(basename "$f" .crt)
    # Check if $d is not in the list of domains
    if [[ ! " ${domains[@]} " =~ " ${d} " ]]; then
        # If $d is not in domains, remove the file
        rm "/opt/hiddify-manager/data/ssl/$d.crt"
        rm "/opt/hiddify-manager/data/ssl/$d.crt.key"
    fi
done

# we need at least one ssl certificate to be able to run haproxy
for d in $domains; do
    (bash /opt/hiddify-manager/services/acme.sh/generate_self_signed_cert.sh $d >/dev/null 2>&1)
done

hiddify-panel-cli dump-server-configs "$HIDDIFY_GENERATED" || {
    echo "Failed to dump server configs into $HIDDIFY_GENERATED" >&2
    exit 1
}
link_generated_server_configs
if getent group hiddify-common >/dev/null 2>&1; then
    for f in "${HIDDIFY_SERVER_CONFIG_FILES[@]}"; do
        if [ -f "$HIDDIFY_GENERATED/$f" ]; then
            chmod 640 "$HIDDIFY_GENERATED/$f"
            chown hiddify-panel:hiddify-common "$HIDDIFY_GENERATED/$f"
        fi
    done
fi

# Remaining .j2 templates (run.sh, firewall, ssh, …) — not dump-server-configs output.
/opt/hiddify-manager/scripts/common/jinja.py $MODE
