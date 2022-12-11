echo "trojan-go install.sh $*"
systemctl stop trojan-go.service

wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-$(dpkg --print-architecture).zip

unzip trojan-go-linux-$(dpkg --print-architecture).zip

ln -s $(pwd)/trojan-go.service /etc/systemd/system/trojan-go.service
