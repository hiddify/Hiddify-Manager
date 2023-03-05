

pkg=$(dpkg --print-architecture)

wget -c https://github.com/MetaCubeX/Clash.Meta/releases/download/v1.14.2/clash.meta-linux-$pkg-v1.14.2.gz

gunzip -f clash.meta-linux-*
rm -rf clash.meta-linux-*.gz
mv clash.meta-linux-* clashmeta
chmod +x clashmeta

ln -sf $(pwd)/clash-server.service /etc/systemd/system/clash-server.service







