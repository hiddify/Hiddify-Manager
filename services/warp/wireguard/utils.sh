# WARP WireGuard helpers — source after scripts/common/utils.sh
source /opt/hiddify-manager/services/warp/utils.sh

function warp_wireguard_real_test() {
    # curl 8.18 refuses ".5" ("expected a proper numerical parameter"): WARP looked broken every time
    curl -s --interface warp --connect-timeout 3 --max-time 8 "http://ip-api.com?fields=message,country,org,query"
    local error=$?
    if [ "$error" = 0 ]; then
        success "WARP is WORKING!"
    else
        warning "WARP is not working!"
    fi
    return $error
}

function generate_warp_wireguard_config() {
    # Generate into a temp file and only replace the live profile after
    # post-processing succeeded; without "Table = off" wg-quick hijacks the
    # default route and the server loses connectivity.
    local svc_dir="${1:-.}"
    local data="$HIDDIFY_DATA/services/warp/wireguard"
    local profile="$data/wgcf-profile.conf"
    local tmp
    echo "Generating WARP config..."
    mkdir -p "$data"
    tmp=$(mktemp "$data/.wgcf-profile.conf.XXXXXX") || return 1
    if ! (cd "$svc_dir" && ./wgcf generate -p "$tmp" >/dev/null 2>&1) || ! grep -q '^\[Peer\]' "$tmp"; then
        error "Failed to generate WARP config"
        rm -f "$tmp"
        return 1
    fi
    sed -i 's/\[Peer\]/Table = off\n\[Peer\]/g' "$tmp"
    sed -i 's/MTU = 1280/MTU = 1320/g' "$tmp"
    curl --connect-timeout 1 -s https://v6.ident.me/ 2>&1 >/dev/null
    if [ $? != 0 ] || [ "$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)" = 1 ]; then
        echo "Removing IPV6 from WARP..."
        sed -i '/Address = [0-9a-fA-F:]\{4,\}/s/^/# /' "$tmp"
    fi
    sed -i '/DNS = 1.1.1.1/s/^/# /' "$tmp"
    if ! grep -q '^Table = off$' "$tmp" || ! grep -q '^PrivateKey = ' "$tmp"; then
        error "WARP config post-processing failed; keeping the previous config"
        rm -f "$tmp"
        return 1
    fi
    chmod 600 "$tmp"
    mv -f "$tmp" "$profile" || { rm -f "$tmp"; return 1; }
    ensure_warp_data_links wireguard "$svc_dir"
    install_warp_wireguard_profile "$profile"
    systemctl enable wg-quick@warp
}

function install_warp_wireguard_profile() {
    # wg-quick is confined by AppArmor to /etc/wireguard. readlink -f follows
    # a symlink into data/, and that open is denied. 660 is enough because the
    # file stays in the same group as the directory.
    local profile="$1"
    mkdir -p /etc/wireguard
    rm -f /etc/wireguard/warp.conf
    cp -f "$profile" /etc/wireguard/warp.conf
    chgrp --reference=/etc/wireguard /etc/wireguard/warp.conf
    chmod 660 /etc/wireguard/warp.conf
}

function reset_warp_wireguard_account() {
    # Broken / banned wgcf accounts stay on disk forever otherwise: update fails and we never register again.
    local svc_dir="${1:-.}"
    echo "Resetting WARP account..."
    mv "$svc_dir/wgcf-account.toml" "$svc_dir/wgcf-account.toml.backup" 2>/dev/null || true
    rm -f "$svc_dir/wgcf-account.toml"
    (cd "$svc_dir" && ./wgcf register --accept-tos -m hiddify -n "$(hostname)") || return $?
    ensure_warp_data_links wireguard "$svc_dir"
}

function check_warp_wireguard_connection() {
    local svc_dir="${1:-.}"
    echo "Checking WARP ..."
    if ! [ -f "$svc_dir/wgcf-account.toml" ]; then
        reset_warp_wireguard_account "$svc_dir" || return $?
    fi
    if ! (cd "$svc_dir" && ./wgcf update >/dev/null 2>&1); then
        warning "WARP account update failed; registering a new account"
        reset_warp_wireguard_account "$svc_dir" || return $?
        (cd "$svc_dir" && ./wgcf update >/dev/null 2>&1) || return $?
    fi
    if ! generate_warp_wireguard_config "$svc_dir"; then
        warning "WARP config generate failed; registering a new account"
        reset_warp_wireguard_account "$svc_dir" || return $?
        (cd "$svc_dir" && ./wgcf update >/dev/null 2>&1) || return $?
        generate_warp_wireguard_config "$svc_dir" || return $?
    fi
    # A warp interface left from an earlier try (not owned by the unit) makes wg-quick fail with "already exists"
    systemctl stop wg-quick@warp >/dev/null 2>&1
    ip link show warp >/dev/null 2>&1 && ip link delete warp
    systemctl start wg-quick@warp
    echo "Starting WARP... checking real connectivity"
    sleep 2  # the first WireGuard handshake
    if ! warp_wireguard_real_test; then
        sleep 3
        echo "Checking real connectivity again"
        warp_wireguard_real_test || return $?
    fi
}
