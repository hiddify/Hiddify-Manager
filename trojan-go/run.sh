systemctl kill trojan-go.service
ln -s $(pwd)/trojan-go.service /etc/systemd/system/trojan-go.service
systemctl enable trojan-go.service

systemctl restart trojan-go.service
