source ./awg_utils.sh

link_awg_config || exit 1

if systemctl is-active --quiet "$AWG_UNIT"; then
    # Peers and settings change without dropping the tunnels (awg syncconf); the address or port needs a restart.
    systemctl reload "$AWG_UNIT" || systemctl restart "$AWG_UNIT"
else
    systemctl enable --now "$AWG_UNIT"
fi
