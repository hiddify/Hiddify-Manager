#!/bin/bash

# Change to the directory of the script
cd "$(dirname -- "$0")"

# Function to get current WARP IP
get_current_warp_ip() {
    curl -s --interface warp --connect-timeout 0.5 http://v4.ident.me
}
change_warp_ip() {
    if [ ! -f wgcf-account.toml ]; then
        bash run.sh
    fi
    systemctl restart wg-quick@warp
    return
    echo "Trying to change IP"
    # Update WARP configuration
    # wget -qN https://gitlab.com/fscarmen/warp/-/raw/main/api.sh
    # bash api.sh -u -f wgcf-account.toml

    # Backup the existing configuration
    mv wgcf-account.toml wgcf-account.toml.backup

    # Download and run WARP
    # Uncomment these lines if needed
    # curl --connect-timeout 1 -Lo wgcf.zip https://api.zeroteam.top/warp?format=wgcf
    # unzip -o wgcf.zip
    bash run.sh

}

current_warp_ip=$(get_current_warp_ip)
echo "Your current WARP IP is $current_warp_ip"

change_warp_ip
new_warp_ip=$(get_current_warp_ip)

until [ "$current_warp_ip" != "$new_warp_ip" ]; do
    echo "new IP $new_warp_ip is the same as the previous one $current_warp_ip "
    sleep 1
    change_warp_ip
    new_warp_ip=$(get_current_warp_ip)
done

echo "WARP IP has been updated from '$current_warp_ip' to '$new_warp_ip'"
    