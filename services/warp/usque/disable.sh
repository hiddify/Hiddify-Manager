systemctl stop --now hiddify-warp.service >/dev/null 2>&1 || true
systemctl disable hiddify-warp.service >/dev/null 2>&1 || true
ip link show warp >/dev/null 2>&1 && ip link delete warp >/dev/null 2>&1 || true
