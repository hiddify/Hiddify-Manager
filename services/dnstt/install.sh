source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/scripts/common/package_manager.sh

download_package dnstm dnstm
if [ "$?" == "0"  ] || ! is_installed ./dnstm; then
    chmod +x dnstm
    set_installed_version dnstm
fi

download_package vaydns dnstt-server


if [ "$?" == "0"  ] || ! is_installed ./dnstt-server; then
    chmod +x dnstt-server
    export PRIVATE_KEY_FILE=/opt/hiddify-manager/services/dnstt/server.key
    export PUBLIC_KEY_FILE=/opt/hiddify-manager/services/dnstt/server.pub
    if [ ! -f "$PUBLIC_KEY_FILE" ]; then
        ./dnstt-server -gen-key -privkey-file "$PRIVATE_KEY_FILE" -pubkey-file "$PUBLIC_KEY_FILE"
    fi 
    
    useradd dnstt
    chown "dnstt":"dnstt" "$PRIVATE_KEY_FILE" "$PUBLIC_KEY_FILE"
    chmod 600 "$PRIVATE_KEY_FILE"
    chmod 644 "$PUBLIC_KEY_FILE"
    set_installed_version vaydns
fi

