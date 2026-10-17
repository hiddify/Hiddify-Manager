# DNS proxy helpers — source after scripts/common/utils.sh

# docker-systemctl-replacement ignores list-unit-files globs and returns every
# unit — always filter client-side to hiddify-<proto>@<instance>.service only.
function dns_proxy_list_proto_instances() {
    local unit="$1"
    local unit_file instance
    while IFS= read -r unit_file; do
        [[ -n "$unit_file" ]] || continue
        case "$unit_file" in
            ${unit}*.service) ;;
            *) continue ;;
        esac
        # Skip the template unit itself (hiddify-dnstt@.service).
        [[ "$unit_file" == "${unit}.service" ]] && continue
        instance="${unit_file#${unit}}"
        printf '%s\n' "${instance%.service}"
    done < <(
        {
            find /etc/systemd/system /run/systemd/system \
                -maxdepth 2 \( -type f -o -type l \) -name "${unit}*.service" 2>/dev/null \
                | xargs -r -n1 basename
            systemctl list-unit-files --no-legend 2>/dev/null | awk '{print $1}'
        } | sort -u
    )
}

function dns_proxy_sync_proto_instances() {
    local proto="$1"
    local gen_root="${2:-$HIDDIFY_GENERATED/dns_proxy}"
    local unit="hiddify-${proto}@"
    local dir="${gen_root}/${proto}"
    local desired=()
    local instance path keep d

    if [[ -d "$dir" ]]; then
        while IFS= read -r -d '' path; do
            instance="$(basename "$(dirname "$path")")"
            [[ -n "$instance" && "$instance" != "." ]] || continue
            desired+=("$instance")
        done < <(find "$dir" -mindepth 2 -maxdepth 2 \( -name 'args' -o -name 'config.json' -o -name 'server_config.toml' \) -print0 2>/dev/null || true)
    fi

    while IFS= read -r instance; do
        [[ -n "$instance" ]] || continue
        keep=0
        for d in "${desired[@]+"${desired[@]}"}"; do
            if [[ "$d" == "$instance" ]]; then
                keep=1
                break
            fi
        done
        if [[ $keep -eq 0 ]]; then
            systemctl disable --now "${unit}${instance}.service" >/dev/null 2>&1 || true
        fi
    done < <(dns_proxy_list_proto_instances "$unit")

    # Restart, not just enable --now: a running instance must pick up new args/keys.
    for instance in "${desired[@]+"${desired[@]}"}"; do
        systemctl enable "${unit}${instance}.service" >/dev/null 2>&1 || true
        systemctl restart "${unit}${instance}.service" || true
    done
}

# hiddifypanel's include_path() writes each sidecar to <proto>/<slug> as a plain
# file, while the units read <proto>/<slug>/args (server_config.toml for masterdns).
function dns_proxy_normalize_layout() {
    local gen_root="$1"
    local f
    for f in "$gen_root"/dnstt/* "$gen_root"/slipstream/*; do
        [[ -f "$f" ]] || continue
        mv "$f" "$f.tmp" && mkdir -p "$f" && mv "$f.tmp" "$f/args"
    done
    for f in "$gen_root"/masterdns/*; do
        [[ -f "$f" ]] || continue
        mv "$f" "$f.tmp" && mkdir -p "$f" && mv "$f.tmp" "$f/server_config.toml"
    done
}

# MasterDnsVPN ignores a key whose length does not fit DATA_ENCRYPTION_METHOD and
# generates a random one instead, so clients could never match it. The panel key
# is 64 hex chars; write the prefix the configured method expects.
function dns_proxy_write_masterdns_keys() {
    local gen_root="$1"
    local key dir method len
    key="$(hconfig master_dns_encrypt_key 2>/dev/null)" || true
    [[ -n "$key" && "$key" != "null" ]] || return 0
    for dir in "$gen_root"/masterdns/*/; do
        [[ -f "$dir/server_config.toml" ]] || continue
        method="$(sed -nE 's/^[[:space:]]*DATA_ENCRYPTION_METHOD[[:space:]]*=[[:space:]]*([0-9]+).*/\1/p' "$dir/server_config.toml" | head -n1)"
        case "$method" in
            3) len=16 ;;
            4) len=24 ;;
            *) len=32 ;;
        esac
        printf '%s' "${key:0:len}" >"$dir/encrypt_key.txt"
    done
}

# The panel (hiddify-panel) wipes and rewrites this tree on every dump, so it must
# stay the owner; the tunnel units run as dns_proxy and only need group access.
function dns_proxy_fix_permissions() {
    local gen_root="$1"
    chown -R hiddify-panel:dns_proxy "$gen_root" 2>/dev/null || true
    chmod -R g+rwX,o-rwx "$gen_root" 2>/dev/null || true
}

# IPv4 address of the interface the default route uses (the server's own address, as the kernel would send from).
function dns_proxy_listen_ip() {
    ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "src") { print $(i + 1); exit }}'
}

# Render the router's config dir (dnstm reads <dir>/config.json) from the panel's
# dnstm.json. Returns 1 when there is no tunnel to route.
function dns_proxy_write_router_config() {
    local src="$1"
    local dir="$2"
    [[ -f "$src" ]] && jq -e '(.tunnels // []) | length > 0' "$src" >/dev/null 2>&1 || return 1
    mkdir -p "$dir"
    # The panel asks for 0.0.0.0:53 when there are tunnels (127.0.0.1:53 from panels before the template fix). A
    # wildcard :53 clashes with a local resolver (systemd-resolved holds 127.0.0.53:53 / 127.0.0.54:53), so listen on
    # the default-route interface address instead: reachable from outside (behind NAT, the address it is forwarded to).
    local ip
    ip=$(dns_proxy_listen_ip)
    jq --arg addr "${ip:-0.0.0.0}:53" \
        'if (.listen.address // "") | test("^(0\\.0\\.0\\.0|127\\.)") then .listen.address = $addr else . end' \
        "$src" >"$dir/config.json.tmp" || return 1
    mv -f "$dir/config.json.tmp" "$dir/config.json"
    chown -R root:dns_proxy "$dir" 2>/dev/null || true
    chmod 750 "$dir"
    chmod 640 "$dir/config.json"
}
