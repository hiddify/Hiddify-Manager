latest=$1
source /opt/hiddify-manager/scripts/common/package_manager.sh
add_package singbox $latest arm64 https://github.com/hiddify/hiddify-core/releases/download/v$latest/hiddify-core-linux-arm64.tar.gz
add_package singbox $latest amd64 https://github.com/hiddify/hiddify-core/releases/download/v$latest/hiddify-core-linux-amd64.tar.gz
