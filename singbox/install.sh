source ../common/utils.sh
rm -rf configs/*.template
# latest= #$(get_release_version hiddify-sing-box)
latest=1.7.8.h2

if [ "$(cat VERSION)" != "$latest" ] || ! is_installed ./sing-box; then
    pkg=$(dpkg --print-architecture)

    curl -Lo sb.zip https://github.com/hiddify/hiddify-sing-box/releases/download/v$latest/sing-box-linux-$pkg.zip

    unzip -o sb.zip
    cp -f sing-box-*/sing-box .
    echo $latest >VERSION
    rm -r sb.zip sing-box-*
    chown root:root sing-box
    chmod +x sing-box
    ln -sf /opt/hiddify-manager/singbox/sing-box /usr/bin/sing-box
    rm geosite.db
fi
