
systemctl kill ss-v2ray.service
systemctl kill ss-faketls.service

ln -s $(pwd)/ss-faketls.service /etc/systemd/system/ss-faketls.service
ln -s $(pwd)/ss-v2ray.service /etc/systemd/system/ss-v2ray.service

systemctl enable ss-v2ray.service
systemctl enable ss-faketls.service

systemctl restart ss-v2ray.service
systemctl restart ss-faketls.service