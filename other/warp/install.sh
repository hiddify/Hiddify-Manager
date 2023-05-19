
if ! [ -f "wgcf-profile.conf" ];then
    TAR="https://api.github.com/repos/ViRb3/wgcf/releases/latest"
    ARCH=$(dpkg --print-architecture)
    URL=$(curl -fsSL ${TAR} | grep 'browser_download_url' | cut -d'"' -f4 | grep linux | grep "${ARCH}")
    curl -fsSL "${URL}" -o ./wgcf && chmod +x ./wgcf && mv ./wgcf /usr/bin
    wgcf register --accept-tos && wgcf generate   
fi



ARCHITECTURE=$(dpkg --print-architecture)



latest=$(wget -qO- -T1 -t1 https://gitlab.com/api/v4/projects/ProjectWARP%2Fwarp-go/releases | awk -F '"' '{for (i=0; i<NF; i++) if ($i=="tag_name") {print $(i+2); exit}}' | sed "s/v//")
latest=${latest:-'1.0.8'}
wget --no-check-certificate -qO /tmp/warp-go.tar.gz https://raw.githubusercontent.com/fscarmen/warp/main/warp-go/warp-go_"$latest"_linux_"$ARCHITECTURE".tar.gz
tar xzf /tmp/warp-go.tar.gz -C /tmp/ warp-go
chmod +x /tmp/warp-go
rm -f /tmp/warp-go.tar.gz
mv /tmp/warp-go .