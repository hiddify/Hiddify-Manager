#!/bin/bash
ln -sf $(pwd)/hiddify-warp.service /etc/systemd/system/hiddify-warp.service
systemctl enable hiddify-warp.service

# if [[ $warp_mode == 'disabled' ]];then
#   bash disable.sh
# else

if ! [ -f "wgcf-account.toml" ];then
    mv wgcf-account.toml wgcf-account.toml.backup
    wgcf register --accept-tos && wgcf generate   
fi

#api.zeroteam.top/warp?format=wgcf for change warp
export WGCF_LICENSE_KEY=$WARP_PLUS_CODE
wgcf update
if [ $? != 0 ];then
  mv wgcf-account.toml wgcf-account.toml.backup
  wgcf update
fi 


#!/bin/bash

# Read the contents of the file
toml_content=$(cat wgcf-account.toml)

# Extract the values using pattern matching
access_token=$(echo "$toml_content" | grep -oP "access_token = '[^']+'" | sed "s/access_token = '\([^']\+\)'/\1/")
device_id=$(echo "$toml_content" | grep -oP "device_id = '[^']+'" | sed "s/device_id = '\([^']\+\)'/\1/")
private_key=$(echo "$toml_content" | grep -oP "private_key = '[^']+'" | sed "s/private_key = '\([^']\+\)'/\1/")

# Prepare the new TOML content
new_toml="[Account]
Device     = $device_id
PrivateKey = $private_key
Token      = $access_token
Type       = plus
Name       = WARP
MTU        = 1420
"

# Write the new TOML content to a file
echo "$new_toml" > warp.conf

./warp-go --config=warp.conf --export-singbox=warp-singbox.json


sed -i "s|2000|3000|g" warp-singbox.json
curl --connect-timeout 1 -s http://ipv6.google.com 2>&1 >/dev/null
if [ $? != 0 ]; then
sed -i 's/"local_address":\[[^]]*\]/"local_address":["172.16.0.2\/32"]/' warp-singbox.json

fi


# while read -r line; do
#     if [[ "$line" == \[*] ]]; then
#         section=${line#[}
#         section=${section%]}
#     elif [[ "$line" =~ ^[[:space:]]*([^[:space:]]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
#         key=${BASH_REMATCH[1]}
#         value=${BASH_REMATCH[2]}
#         var="${section}_${key}"
#         value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//')
#         export "$var"="$value"
#     fi
# done < "wgcf-profile.conf"


# cat > xray_warp_conf.json << EOM
#     {
#       "tag": "WARP",
#       "protocol": "wireguard",
#       "settings": {
#         "secretKey": "$Interface_PrivateKey",
#         "address": [
#           "172.16.0.2/32",
#           "$Interface_Address"
#         ],
#         "peers": [
#           {
#             "publicKey": "$Peer_PublicKey",
#             "endpoint": "$Peer_Endpoint"
#           }
#         ],
#         "reserved":[0, 0, 0], 
#         "mtu": 1280
#       }
#     }
# EOM


# peer_domain="${Peer_Endpoint%%:*}"
# peer_port="${Peer_Endpoint#*:}"

# cat > singbox_warp_conf.json << EOM
# {
#   "type": "wireguard",
#   "tag": "WARP",
#   "server": "$peer_domain",
#   "server_port": $peer_port,
#   "system_interface": false,

#   "local_address": [
#     "172.16.0.2/32",
#     "$Interface_Address"
#   ],
#   "private_key": "$Interface_PrivateKey",
#   "peer_public_key": "$Peer_PublicKey",
#   "reserved": [0, 0, 0],
#   "mtu": 1280
# }

# EOM
#"interface_name": "wg0",
#"pre_shared_key": "31aIhAPwktDGpH4JDhA8GNvjFXEf/a6+UaQRyOAiyfM=",
#"workers": 8,
# warp_conf=$(cat xray_warp_conf.json)
# warp_conf=$(echo "$warp_conf" | tr '\n' ' ')
# escaped_warp_conf=$(printf '%s\n' "$warp_conf" | sed -e 's/[\/&]/\\&/g')
# sed "s|//hiddify_warp|$escaped_warp_conf|g"  xray_demo.json.template > xray_demo.json

# singbox_warp_conf=$(cat singbox_warp_conf.json)
# singbox_warp_conf=$(echo "$singbox_warp_conf" | tr '\n' ' ')
# escaped_singbox_warp_conf=$(printf '%s\n' "$singbox_warp_conf" | sed -e 's/[\/&]/\\&/g')
# sed "s|//hiddify_warp|$escaped_singbox_warp_conf|g"  singbox_demo.json.template > singbox_demo.json
# sed "s|//hiddify_warp|$escaped_singbox_warp_conf|g"  warp-singbox.json.template > warp-singbox.json



# xray -c xray_demo.json >/dev/null  &
# pid=$!
# sleep 3
# curl -x socks://127.0.0.1:1230 www.ipinfo.io
# curl -x socks://127.0.0.1:1230 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query
# if [ $? != 0 ];then
#     rm xray_warp_conf.json
# else
#    echo ""
#    echo "==========WARP is working=============="
# fi
# kill -9 $pid



# echo "Testing singbox warp"

# sing-box run -c singbox_demo.json >/dev/null  &
# pid=$!
# sleep 3
# curl -x socks://127.0.0.1:1231 www.ipinfo.io
# curl -x socks://127.0.0.1:1231 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query
# if [ $? != 0 ];then
#     rm singbox_warp_conf.json
# else
#    echo ""
#    echo "==========WARP is working=============="
# fi
# kill -9 $pid



systemctl reload hiddify-warp.service
systemctl start  hiddify-warp.service
#systemctl status hiddify-warp.service

sleep 5
echo "Testing singbox warp"


curl -x socks://127.0.0.1:3000 --connect-timeout 4 www.ipinfo.io
curl -x socks://127.0.0.1:3000 --connect-timeout 4 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query
if [ $? != 0 ];then
    echo "WARP is not working"
else
   echo ""
   echo "==========WARP is working=============="
fi

# echo "Remaining..."
# bash check-quota.sh
# fi