systemctl stop hiddify-ss-v2ray.service > /dev/null 2>&1
systemctl stop hiddify-ss-faketls.service > /dev/null 2>&1

systemctl disable hiddify-ss-v2ray.service > /dev/null 2>&1
systemctl disable hiddify-ss-faketls.service > /dev/null 2>&1