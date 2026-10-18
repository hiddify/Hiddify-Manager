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
    for f in wgcf-account.toml wgcf-account.toml.backup warp.conf wgcf-profile.conf; do
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
