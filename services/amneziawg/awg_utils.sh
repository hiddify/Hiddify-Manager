# AmneziaWG (awg-quick from the amneziawg-tools package): its own interface next to WireGuard's hiddifywg.
# The panel writes the config to generated/amneziawg.conf; awg-quick reads /etc/amnezia/amneziawg/<if>.conf (a link to it).
SERVER_AWG_NIC=hiddifyawg
AWG_GENERATED=/opt/hiddify-manager/generated/amneziawg.conf
AWG_CONF_DIR=/etc/amnezia/amneziawg
AWG_UNIT="awg-quick@${SERVER_AWG_NIC}"

# Link the generated config where awg-quick looks for it. Fails when the panel has not written it yet.
link_awg_config() {
    if [ ! -s "$AWG_GENERATED" ]; then
        echo "Missing $AWG_GENERATED"
        return 1
    fi
    mkdir -p "$AWG_CONF_DIR"
    chmod 700 "$AWG_CONF_DIR"
    ln -sfn "$AWG_GENERATED" "$AWG_CONF_DIR/${SERVER_AWG_NIC}.conf"
}
