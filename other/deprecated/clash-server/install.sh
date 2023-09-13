
pkg=$(dpkg --print-architecture)

version="v1.14.2"

filename="clash.meta-linux-$pkg-$version.gz"

if grep -q avx2 /proc/cpuinfo; then
    echo "CPU is compatible with AVX2"
else
    echo "CPU is not compatible with AVX2"
    filename="clash.meta-linux-$pkg-compatible-$version.gz"
fi

wget -c https://github.com/MetaCubeX/Clash.Meta/releases/download/$version/$filename

gunzip -f clash.meta-linux-*
mv clash.meta-linux-* clashmeta
chmod +x clashmeta

ln -sf $(pwd)/clash-server.service /etc/systemd/system/clash-server.service







