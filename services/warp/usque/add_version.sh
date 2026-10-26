latest=$1
SCRIPT_DIR="$(cd "$(dirname -- "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../scripts/common/package_manager.sh"
add_package usque "$latest" amd64 "https://github.com/Diniboy1123/usque/releases/download/v${latest}/usque_${latest}_linux_amd64.zip"
add_package usque "$latest" arm64 "https://github.com/Diniboy1123/usque/releases/download/v${latest}/usque_${latest}_linux_arm64.zip"
