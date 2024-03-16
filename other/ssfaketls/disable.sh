systemctl stop ss-v2ray.service > /dev/null 2>&1
systemctl stop ss-faketls.service > /dev/null 2>&1

systemctl disable ss-v2ray.service > /dev/null 2>&1
systemctl disable ss-faketls.service > /dev/null 2>&1