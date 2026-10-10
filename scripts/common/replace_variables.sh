cd $(dirname -- "$0")
source ./utils.sh
activate_python_venv
ensure_hiddify_data_dirs

if ! is_valid_current_json /opt/hiddify-manager/data/current.json; then
    error "Invalid /opt/hiddify-manager/data/current.json; not applying configs"
    exit 1
fi
domains=$(jq -r '.domains[] | .domain' /opt/hiddify-manager/data/current.json | tr '\n' ' ')

# Remove certificates of domains that are no longer in the panel. current.json is
# validated above, and an empty domain list never deletes anything.
if [ -z "${domains// /}" ]; then
    warning "No domains in current.json; keeping existing certificates"
else
    # Self-signed certs of names longer than 64 chars are stored truncated.
    cert_names=" "
    for d in $domains; do
        cert_names+="$d ${d:0:64} "
    done
    for f in /opt/hiddify-manager/data/ssl/*.crt; do
        [ -e "$f" ] || continue
        d=$(basename "$f" .crt)
        # Wildcard domains are never dumped to current.json; keep their certs.
        [[ "$d" == *"*"* ]] && continue
        if [[ "$cert_names" != *" $d "* ]]; then
            echo "Domain $d is no longer in the panel; deleting its certificate"
            rm -f "/opt/hiddify-manager/data/ssl/$d.crt" "/opt/hiddify-manager/data/ssl/$d.crt.key"
        fi
    done
fi
rm -f /opt/hiddify-manager/data/services/acme.sh/panel_domains

# we need at least one ssl certificate to be able to run haproxy
for d in $domains; do
    (bash /opt/hiddify-manager/services/acme.sh/generate_self_signed_cert.sh $d >/dev/null 2>&1)
done

ensure_generated_permissions
dump_server_configs || {
    echo "Failed to dump server configs into $HIDDIFY_GENERATED" >&2
    exit 1
}
ensure_generated_permissions

# Remaining .j2 templates (run.sh, firewall, ssh, …) — not dump-server-configs output.
/opt/hiddify-manager/scripts/common/jinja.py $MODE
