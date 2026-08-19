latest=$1
source /opt/hiddify-manager/scripts/common/package_manager.sh
add_package telemt $latest arm64 https://github.com/telemt/telemt/releases/download/$latest/telemt-aarch64-linux-gnu.tar.gz
add_package telemt $latest amd64 https://github.com/telemt/telemt/releases/download/$latest/telemt-x86_64-linux-gnu.tar.gz
