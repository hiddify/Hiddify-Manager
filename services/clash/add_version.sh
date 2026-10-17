latest=$1
source ../../scripts/common/package_manager.sh
add_package clash $latest amd64 https://github.com/MetaCubeX/mihomo/releases/download/v$latest/mihomo-linux-amd64-v$latest.gz
add_package clash $latest arm64 https://github.com/MetaCubeX/mihomo/releases/download/v$latest/mihomo-linux-arm64-v$latest.gz
