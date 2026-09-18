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

    for instance in "${desired[@]+"${desired[@]}"}"; do
        systemctl enable --now "${unit}${instance}.service" >/dev/null 2>&1 || systemctl restart "${unit}${instance}.service" || true
    done
}
