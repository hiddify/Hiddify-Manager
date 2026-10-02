latest=0.2.4
source ../../scripts/common/package_manager.sh
add_package rpxy-l4 "$latest" amd64 "https://github.com/junkurihara/rust-rpxy-l4/releases/download/${latest}/rpxy-l4-x86_64-unknown-linux-musl.tar.gz"
add_package rpxy-l4 "$latest" arm64 "https://github.com/junkurihara/rust-rpxy-l4/releases/download/${latest}/rpxy-l4-aarch64-unknown-linux-musl.tar.gz"
