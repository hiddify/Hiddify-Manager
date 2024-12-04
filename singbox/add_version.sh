latest=$1
source ../common/package_manager.sh
add_package singbox $latest arm64 https://github.com/hiddify/hiddify-sing-box/releases/download/v$latest/sing-box-linux-arm64.zip
add_package singbox $latest amd64 https://github.com/hiddify/hiddify-sing-box/releases/download/v$latest/sing-box-linux-amd64.zip