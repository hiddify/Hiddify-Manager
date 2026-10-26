# WARP helpers — source after scripts/common/utils.sh

function ensure_warp_data_links() {
    # Move permanent WARP account/config files into data/ and symlink them back.
    # A fresh real file in svc_dir (e.g. after wgcf register) replaces the data/ copy —
    # otherwise a broken account in data/ is kept forever and the new register is deleted.
    local kind="${1:?}"
    local svc_dir="${2:-.}"
    local data="$HIDDIFY_DATA/services/warp/$kind"
    mkdir -p "$data"
    local f src dst
    for f in wgcf-account.toml wgcf-account.toml.backup warp.conf wgcf-profile.conf config.json config.json.backup; do
        src="$svc_dir/$f"
        dst="$data/$f"
        if [ -f "$src" ] && [ ! -L "$src" ]; then
            mv -f "$src" "$dst"
        fi
        if [ -e "$dst" ]; then
            ln -sfn "$dst" "$src"
        fi
    done
}

# True when the kernel has IPv6 on and it reaches the internet.
function warp_host_has_ipv6() {
    [ -d /proc/sys/net/ipv6 ] || return 1
    [ "$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null)" = 1 ] && return 1
    curl --connect-timeout 1 -s https://v6.ident.me/ >/dev/null 2>&1
}
