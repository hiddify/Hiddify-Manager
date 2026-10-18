#!/bin/bash
#ln -sf $(pwd)/hiddify-warp.service /etc/systemd/system/hiddify-warp.service
source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/warp/wireguard/utils.sh
ensure_warp_data_links wireguard "$(pwd)"
systemctl disable hiddify-warp.service >/dev/null 2>&1

#api.zeroteam.top/warp?format=./wgcf for change warp
export WGCF_LICENSE_KEY="{{hconfigs['warp_plus_code']}}"
if ! check_warp_wireguard_connection "$(pwd)"; then
  # Do not mv+relink: that restores the same broken account from data/.
  reset_warp_wireguard_account "$(pwd)"
  if ! check_warp_wireguard_connection "$(pwd)"; then
    reset_warp_wireguard_account "$(pwd)"
    export WGCF_LICENSE_KEY=
    if ! check_warp_wireguard_connection "$(pwd)"; then
      error "!!!!!!!!!!!!!!! WARP ERROR"
    fi
  fi
fi
