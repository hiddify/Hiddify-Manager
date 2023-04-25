sudo apt-get install -y socat
sudo apt-get remove -y certbot
rm -rf /opt/hiddify/

mkdir -p /opt/hiddify-config/acme.sh/lib/
curl -L https://get.acme.sh| sh -s -- home /opt/hiddify-config/acme.sh/lib \
    --config-home /opt/hiddify-config/acme.sh/lib/data \
    --cert-home  /opt/hiddify-config/acme.sh/lib/certs

sed -i 's|_sleep_overload_retry_sec=$_retryafter|_sleep_overload_retry_sec=$_retryafter; if [[ "$_retryafter" > 20 ]];then return 10; fi|g' lib/acme.sh
./lib/acme.sh --register-account -m my@example.com
mkdir -p ../ssl/