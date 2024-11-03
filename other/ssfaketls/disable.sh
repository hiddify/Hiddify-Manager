systemctl stop hiddify-ss-v2ray.service > /dev/null 2>&1
systemctl stop hiddify-ss-faketls.service > /dev/null 2>&1

systemctl disable --now ss-v2ray.service > /dev/null 2>&1
systemctl disable --now ss-faketls.service > /dev/null 2>&1

systemctl disable --now hiddify-ss-v2ray.service > /dev/null 2>&1
systemctl disable --now hiddify-ss-faketls.service > /dev/null 2>&1
rm ss-faketls.service* > /dev/null 2>&1