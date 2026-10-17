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
# Certificates: the panel writes data/cert from its database: a self-signed one for a domain with none (HAProxy does not
# start without), the files of removed domains deleted. It gets the real ones itself (hiddifypanel/acme).
ensure_cert_dir
hiddify-panel-cli export-certificates || warning "Could not write the certificates from the panel"
timing "certificates"

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
