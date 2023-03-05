

pkg=$(dpkg --print-architecture)

if [[ $pkg == "arm64" ]];then 
wget -O shadowtls -c https://github.com/ihciah/shadow-tls/releases/download/v0.2.18/shadow-tls-aarch64-unknown-linux-musl
else
wget -O shadowtls -c https://github.com/ihciah/shadow-tls/releases/download/v0.2.18/shadow-tls-x86_64-unknown-linux-musl
fi
chmod +x shadowtls


ln -sf $(pwd)/shadowtls.service /etc/systemd/system/shadowtls.service







