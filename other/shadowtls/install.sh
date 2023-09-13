source ../../common/utils.sh

if ! is_installed ./shadowtls; then
    pkg=$(dpkg --print-architecture)

    systemctl stop shadowtls
    if [[ $pkg == "arm64" ]]; then
        wget -O shadowtls -c https://github.com/ihciah/shadow-tls/releases/latest/download/shadow-tls-aarch64-unknown-linux-musl
    else
        wget -O shadowtls -c https://github.com/ihciah/shadow-tls/releases/latest/download/shadow-tls-x86_64-unknown-linux-musl
    fi
    chmod +x shadowtls

    ln -sf $(pwd)/shadowtls.service /etc/systemd/system/shadowtls.service
fi
