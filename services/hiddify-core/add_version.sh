latest=$1
source ../../scripts/common/package_manager.sh
add_package hiddify-core $latest arm64 https://github.com/hiddify/hiddify-core/releases/download/v$latest/hiddify-core-linux-arm64-glibc.tar.gz
add_package hiddify-core $latest amd64 https://github.com/hiddify/hiddify-core/releases/download/v$latest/hiddify-core-linux-amd64-glibc.tar.gz
