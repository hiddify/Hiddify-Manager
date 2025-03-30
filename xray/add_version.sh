latest=$1
source ../common/package_manager.sh
add_package xray $latest arm64 https://github.com/XTLS/Xray-core/releases/download/v$latest/Xray-linux-arm64-v8a.zip
add_package xray $latest amd64 https://github.com/XTLS/Xray-core/releases/download/v$latest/Xray-linux-64.zip