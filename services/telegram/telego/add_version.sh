latest=$1
source /opt/hiddify-manager/scripts/common/package_manager.sh
add_package telego "$latest" arm64 "https://github.com/Scratch-net/telego/releases/download/v$latest/telego_${latest}_linux_arm64.tar.gz"
add_package telego "$latest" amd64 "https://github.com/Scratch-net/telego/releases/download/v$latest/telego_${latest}_linux_amd64.tar.gz"
