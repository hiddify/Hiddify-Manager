systemctl kill ss-v2ray.service

ln -sf $(pwd)/ss-v2ray.service /etc/systemd/system/ss-v2ray.service

systemctl enable ss-v2ray.service


systemctl restart ss-v2ray.service
