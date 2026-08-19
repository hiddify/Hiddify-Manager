latest=$1
source /opt/hiddify-manager/scripts/common/package_manager.sh
add_package vaydns $latest arm64 https://github.com/net2share/vaydns/releases/download/v$latest/vaydns-server-linux-arm64
add_package vaydns $latest amd64 https://github.com/net2share/vaydns/releases/download/v$latest/vaydns-server-linux-amd64
