#!/bin/bash
wgcf update

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
      "tag": "WARP-free",
      "protocol": "wireguard",
      "settings": {
        "secretKey": "$Interface_PrivateKey",
        "address": [
          "172.16.0.2/32",
          "fd01:5ca1:ab1e:823e:e094:eb1c:ff87:1fab/128"
        ],
        "peers": [
          {
            "publicKey": "$Peer_PublicKey",
            "endpoint": "$Peer_Endpoint"
          }
        ]
      }
    }
EOM

warp_conf=$(cat xray_warp_conf.json)
warp_conf=$(echo "$warp_conf" | tr '\n' ' ')
escaped_warp_conf=$(printf '%s\n' "$warp_conf" | sed -e 's/[\/&]/\\&/g')
sed "s|\"outbounds\": \[\]|\"outbounds\": [$escaped_warp_conf]|g"  xray_demo.json.template > xray_demo.json
xray -c xray_demo.json &
pid=$!
sleep 3
curl -x socks://127.0.0.1:1234 www.ipinfo.io
if [ $? != 0 ];then
    rm xray_warp_conf.json
else
   echo "Congrat!!! WARP is working"
fi
kill -9 $pid

