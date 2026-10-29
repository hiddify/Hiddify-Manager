source ./awg_utils.sh

systemctl stop "$AWG_UNIT" 2>/dev/null
systemctl disable "$AWG_UNIT" 2>/dev/null
true
