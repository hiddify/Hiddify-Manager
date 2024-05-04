source ../common/utils.sh
rm -rf configs/*.template

# latest= #$(get_release_version hiddify-sing-box)
latest=1.8.8.h4

if [ "$(cat VERSION 2>/dev/null)" != "$latest" ] || ! is_installed ./sing-box; then
    pkg=$(dpkg --print-architecture)
    
    curl -sLo sb.zip https://github.com/hiddify/hiddify-sing-box/releases/download/v$latest/sing-box-linux-$pkg.zip > /dev/null
    
    unzip -o sb.zip > /dev/null
    cp -f sing-box-*/sing-box . 2>/dev/null
    echo $latest >VERSION
    rm -r sb.zip sing-box-* 2>/dev/null
    chown root:root sing-box
    chmod +x sing-box
    ln -sf /opt/hiddify-manager/singbox/sing-box /usr/bin/sing-box
    rm geosite.db 2>/dev/null
fi
