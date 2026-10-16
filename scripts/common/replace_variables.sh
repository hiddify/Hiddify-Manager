cd $(dirname -- "$0")
source ./utils.sh

# Step timing: "[timing] <step> <ms> (total <ms>)" after each step, so a slow apply shows which part is slow.
_timing_start=${EPOCHREALTIME//[.,]/}
_timing_last=$_timing_start
function timing() {
    local now=${EPOCHREALTIME//[.,]/}
    printf '[timing] %-26s %7d ms (total %d ms)\n' "$1" $(((now - _timing_last) / 1000)) $(((now - _timing_start) / 1000))
    _timing_last=$now
}

activate_python_venv
ensure_hiddify_data_dirs
timing "venv and data dirs"


remove_old_server_templates() {
    local base=/opt/hiddify-manager/services
    local t

    # Remove a template together with its rendered output (foo.conf.j2 -> foo.conf)
    remove_template_pair() { rm -f -- "$1" "${1%.j2}"; }

    # Every *.j2 (and its rendered file) under these directories
    local -a dirs=(
        "$base/nginx"
        "$base/haproxy"
        "$base/firewall"
        "$base/wireguard"
        "$base/telegram/telemt"
        "$base/rust-rpxy-l4"
        "$base/xray/configs"
        "$base/hiddify-core/configs"
    )
    while IFS= read -r -d '' t; do
        remove_template_pair "$t"
    done < <(find "${dirs[@]}" -type f -name '*.j2' -print0 2>/dev/null)
}

remove_old_server_templates
# Deprecated services' templates (their own files are removed by remove_deprecated.sh). Only the .j2: telegram's install.sh
# and run.sh are plain scripts now and must not be rendered over.
rm -rf /opt/hiddify-manager/services/v2ray /opt/hiddify-manager/services/telegram/{erlang,orig,python,tgo}
rm -f /opt/hiddify-manager/services/telegram/install.sh.j2 /opt/hiddify-manager/services/telegram/run.sh.j2
timing "remove old templates"


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
timing "remove old certificates"

# we need at least one ssl certificate to be able to run haproxy. Only domains without a usable one (missing, or expiring
# within a day) get a self-signed one, in parallel: each generate_self_signed_cert.sh call takes ~1s (it re-applies the ssl
# folder's permissions), which made this step slow with many domains.
for d in $domains; do
    cert="/opt/hiddify-manager/data/ssl/${d:0:64}.crt"
    if [ -s "$cert" ] && [ -s "$cert.key" ] && openssl x509 -checkend 86400 -noout -in "$cert" >/dev/null 2>&1; then
        continue
    fi
    (bash /opt/hiddify-manager/services/acme.sh/generate_self_signed_cert.sh "$d" >/dev/null 2>&1) &
done
wait
timing "self-signed certificates"

ensure_generated_permissions
dump_server_configs || {
    echo "Failed to dump server configs into $HIDDIFY_GENERATED" >&2
    exit 1
}
ensure_generated_permissions
timing "dump server configs"

# Remaining .j2 templates (run.sh, firewall, ssh, …) — not dump-server-configs output.
/opt/hiddify-manager/scripts/common/jinja.py $MODE
jinja_rc=$?
timing "render .j2 templates"
printf '[timing] replace_variables total: %d ms\n' $(((${EPOCHREALTIME//[.,]/} - _timing_start) / 1000))
exit $jinja_rc
