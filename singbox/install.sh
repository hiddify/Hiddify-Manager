pkg=$(dpkg --print-architecture)

curl -Lo sb.zip https://github.com/hiddify/hiddify-sing-box/releases/latest/download/sing-box-linux-$pkg.zip
unzip -o sb.zip
cp -f sing-box-*/sing-box .
rm -r sb.zip sing-box-*
chown root:root sing-box
chmod +x sing-box

ln -sf /opt/hiddify-config/singbox/sing-box /usr/bin/sing-box

rm geosite.db