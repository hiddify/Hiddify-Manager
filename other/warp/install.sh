
if ! [ -f "wgcf-profile.conf" ];then
    TAR="https://api.github.com/repos/ViRb3/wgcf/releases/latest"
    ARCH=$(dpkg --print-architecture)
    URL=$(curl -fsSL ${TAR} | grep 'browser_download_url' | cut -d'"' -f4 | grep linux | grep "${ARCH}")
    curl -fsSL "${URL}" -o ./wgcf && chmod +x ./wgcf && mv ./wgcf /usr/bin
    wgcf register --accept-tos && wgcf generate   
fi



