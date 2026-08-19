latest=$1
source /opt/hiddify-manager/scripts/common/package_manager.sh
add_package wgcf $latest arm64 https://github.com/ViRb3/wgcf/releases/download/v$latest/wgcf_${latest}_linux_arm64
add_package wgcf $latest amd64 https://github.com/ViRb3/wgcf/releases/download/v$latest/wgcf_${latest}_linux_amd64
