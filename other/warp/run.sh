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


cat > xray/warp_conf.json << EOM
{
  "outbounds": [
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
    ]
}
EOM

xray -confdir xray/ &
pid=$!
sleep 3
curl -x socks://127.0.0.1:1234 www.ipinfo.io
if [ $? != 0 ];then
    rm xray/warp_conf.json
else
   echo "Congrat!!! WARP is working"
fi
kill -9 $pid

