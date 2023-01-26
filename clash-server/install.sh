

pkg=$(dpkg --print-architecture)

wget -c https://github.com/MetaCubeX/Clash.Meta/releases/download/v1.14.1/clash.meta-linux-$pkg-v1.14.1.gz

gunzip -f clash.meta-linux-*
rm -rf clash.meta-linux-*.gz
mv clash.meta-linux-* clashmeta

ln -sf $(pwd)/hiddify-panel.service /etc/systemd/system/clash-server.service







