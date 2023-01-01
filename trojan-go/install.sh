echo "trojan-go install.sh $*"
systemctl kill trojan-go.service

apt install -y unzip 

pkg=$(dpkg --print-architecture)
[[ $pkg == 'arm64' ]] && pkg='arm'

wget -c https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-$pkg.zip

unzip -o trojan-go-linux-* trojan-go



