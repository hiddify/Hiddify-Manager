systemctl kill ss-faketls.service

systemctl enable ss-faketls.service

systemctl restart ss-faketls.service
systemctl status ss-faketls.service --no-pager
