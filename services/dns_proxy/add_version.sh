vaydns=0.2.8
masterdns=2026.06.13.234407-7de2476
slipstream=0.1.1
source ../../scripts/common/package_manager.sh
add_package vaydns $vaydns arm64 https://github.com/net2share/vaydns/releases/download/v$vaydns/vaydns-server-linux-arm64
add_package vaydns $vaydns amd64 https://github.com/net2share/vaydns/releases/download/v$vaydns/vaydns-server-linux-amd64

add_package masterdns $masterdns arm64 https://github.com/masterking32/MasterDnsVPN/releases/download/v$masterdns/MasterDnsVPN_Server_Linux_ARM64.zip
add_package masterdns $masterdns amd64 https://github.com/masterking32/MasterDnsVPN/releases/download/v$masterdns/MasterDnsVPN_Server_Linux_X86.zip

add_package slipstream $slipstream arm64 https://github.com/EndPositive/slipstream/releases/download/v$slipstream/slipstream-server-v0.1.1-linux-arm64
add_package slipstream $slipstream amd64 https://github.com/EndPositive/slipstream/releases/download/v$slipstream/slipstream-server-v0.1.1-linux-x86_64
