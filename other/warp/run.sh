#!/bin/bash

export WGCF_LICENSE_KEY=$WARP_PLUS_CODE
wgcf update
if [ $? != 0 ];then
  mv wgcf-account.toml wgcf-account.toml.backup
  wgcf update
fi 

while read -r line; do
    if [[ "$line" == \[*] ]]; then
        section=${line#[}
        section=${section%]}
    elif [[ "$line" =~ ^[[:space:]]*([^[:space:]]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
        key=${BASH_REMATCH[1]}
        value=${BASH_REMATCH[2]}
        var="${section}_${key}"
        value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//')
        export "$var"="$value"
    fi
done < "wgcf-profile.conf"


cat > xray_warp_conf.json << EOM
    {
      "tag": "WARP",
      "protocol": "wireguard",
      "settings": {
        "secretKey": "$Interface_PrivateKey",
        "address": [
          "172.16.0.2/32",
          "$Interface_Address"
        ],
        "peers": [
          {
            "publicKey": "$Peer_PublicKey",
            "endpoint": "$Peer_Endpoint"
          }
        ],
        "reserved":[0, 0, 0], 
        "mtu": 1280
      }
    }
EOM


peer_domain="${Peer_Endpoint%%:*}"
peer_port="${Peer_Endpoint#*:}"

cat > singbox_warp_conf.json << EOM
{
  "type": "wireguard",
  "tag": "WARP",
  "server": "$peer_domain",
  "server_port": $peer_port,
  "system_interface": false,

  "local_address": [
    "172.16.0.2/32",
    "$Interface_Address"
  ],
  "private_key": "$Interface_PrivateKey",
  "peer_public_key": "$Peer_PublicKey",
  "reserved": [0, 0, 0],
  "mtu": 1280,
  "network": "tcp"
}

EOM
#"interface_name": "wg0",
#"pre_shared_key": "31aIhAPwktDGpH4JDhA8GNvjFXEf/a6+UaQRyOAiyfM=",
#"workers": 8,
warp_conf=$(cat xray_warp_conf.json)
warp_conf=$(echo "$warp_conf" | tr '\n' ' ')
escaped_warp_conf=$(printf '%s\n' "$warp_conf" | sed -e 's/[\/&]/\\&/g')
sed "s|//hiddify_warp|$escaped_warp_conf|g"  xray_demo.json.template > xray_demo.json

singbox_warp_conf=$(cat singbox_warp_conf.json)
singbox_warp_conf=$(echo "$singbox_warp_conf" | tr '\n' ' ')
escaped_singbox_warp_conf=$(printf '%s\n' "$singbox_warp_conf" | sed -e 's/[\/&]/\\&/g')
sed "s|//hiddify_warp|$escaped_singbox_warp_conf|g"  singbox_demo.json.template > singbox_demo.json



xray -c xray_demo.json >/dev/null  &
pid=$!
sleep 3
curl -x socks://127.0.0.1:1234 www.ipinfo.io
curl -x socks://127.0.0.1:1234 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query
if [ $? != 0 ];then
    rm xray_warp_conf.json
else
   echo ""
   echo "==========WARP is working=============="
fi
kill -9 $pid



echo "Testing singbox warp"

sing-box run -c singbox_demo.json >/dev/null  &
pid=$!
sleep 3
curl -x socks://127.0.0.1:1234 www.ipinfo.io
curl -x socks://127.0.0.1:1234 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query
if [ $? != 0 ];then
    rm singbox_warp_conf.json
else
   echo ""
   echo "==========WARP is working=============="
fi
kill -9 $pid

