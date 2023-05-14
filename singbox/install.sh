curl -Lo sb.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.3-beta11/sing-box-1.3-beta11-linux-amd64.tar.gz 
tar -xzf sb.tar.gz 
cp -f sing-box-*/sing-box .
rm -r sb.tar.gz sing-box-*
chown root:root sing-box
chmod +x sing-box

ln -s /opt/hiddify-config/singbox/sing-box /usr/bin/sing-box