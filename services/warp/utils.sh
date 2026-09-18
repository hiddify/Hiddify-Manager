# WARP helpers — source after scripts/common/utils.sh

function ensure_warp_data_links() {
    # Move permanent WARP account/config files into data/ and symlink them back.
    local kind="${1:?}"
    local svc_dir="${2:-.}"
    local data="$HIDDIFY_DATA/services/warp/$kind"
    mkdir -p "$data"
    local f src dst
    for f in wgcf-account.toml wgcf-account.toml.backup warp.conf wgcf-profile.conf; do
        src="$svc_dir/$f"
        dst="$data/$f"
        if [ -f "$src" ] && [ ! -L "$src" ]; then
            if [ ! -e "$dst" ]; then
                mv "$src" "$dst"
            else
                rm -f "$src"
            fi
        fi
        if [ -e "$dst" ]; then
            ln -sfn "$dst" "$src"
        fi
    done
}

function warp_wireguard_real_test() {
    curl -s --interface warp --connect-timeout .5 http://ip-api.com?fields=message,country,org,query
    local error=$?
    if [ "$error" = 0 ]; then
        success "WARP is WORKING!"
    else
        warning "WARP is not working!"
    fi
    return $error
}

function generate_warp_wireguard_config() {
    local svc_dir="${1:-.}"
    echo "Generating WARP config..."
    (cd "$svc_dir" && ./wgcf generate >/dev/null 2>&1)
    sed -i 's/\[Peer\]/Table = off\n\[Peer\]/g' "$svc_dir/wgcf-profile.conf"
    curl --connect-timeout 1 -s https://v6.ident.me/ 2>&1 >/dev/null
    if [ $? != 0 ] || [ "$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)" = 1 ]; then
        echo "Removing IPV6 from WARP..."
        sed -i '/Address = [0-9a-fA-F:]\{4,\}/s/^/# /' "$svc_dir/wgcf-profile.conf"
    fi
    sed -i '/DNS = 1.1.1.1/s/^/# /' "$svc_dir/wgcf-profile.conf"
    mkdir -p /etc/wireguard/
    ensure_warp_data_links wireguard "$svc_dir"
    ln -sf "$svc_dir/wgcf-profile.conf" /etc/wireguard/warp.conf
    systemctl enable wg-quick@warp
}

function check_warp_wireguard_connection() {
    local svc_dir="${1:-.}"
    echo "Checking WARP ..."
    if ! [ -f "$svc_dir/wgcf-account.toml" ]; then
        mv "$svc_dir/wgcf-account.toml" "$svc_dir/wgcf-account.toml.backup" 2>/dev/null || true
        (cd "$svc_dir" && ./wgcf register --accept-tos -m hiddify -n "$(hostname)")
        ensure_warp_data_links wireguard "$svc_dir"
    fi
    (cd "$svc_dir" && ./wgcf update >/dev/null 2>&1) || return $?
    generate_warp_wireguard_config "$svc_dir"
    systemctl restart wg-quick@warp
    echo "Starting WARP.... checking real connectivitiy"
    sleep .5
    if ! warp_wireguard_real_test; then
        sleep .5
        echo "Checking real connectivitiy again!"
        warp_wireguard_real_test || return $?
    fi
}
