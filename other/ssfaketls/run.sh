

systemctl kill ss-faketls.service

ln -sf $(pwd)/ss-faketls.service /etc/systemd/system/ss-faketls.service



systemctl enable ss-faketls.service


systemctl restart ss-faketls.service
systemctl status ss-faketls.service