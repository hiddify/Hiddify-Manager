SERVER_WG_NIC=hiddifywg

allow_wg_quick_read() {
    local path="$1"
    local profile=/etc/apparmor.d/wg-quick
    local local_profile=/etc/apparmor.d/local/wg-quick
    local rule="file r ${path},"
    [ -f "$profile" ] || return 0
    mkdir -p /etc/apparmor.d/local
    grep -qxF "$rule" "$local_profile" 2>/dev/null || echo "$rule" >>"$local_profile"
    apparmor_parser -r "$profile" >/dev/null 2>&1 || true
}
