source ../common/utils.sh
install_package socat
remove_package certbot

mkdir -p /opt/hiddify-manager/acme.sh/lib/
if ! is_installed ./lib/acme.sh; then
    curl -s -L https://get.acme.sh | sh -s -- home /opt/hiddify-manager/acme.sh/lib \
    --config-home /opt/hiddify-manager/acme.sh/lib/data \
    --cert-home /opt/hiddify-manager/acme.sh/lib/certs --nocron
    
    sed -i 's|_sleep_overload_retry_sec=$_retryafter|_sleep_overload_retry_sec=$_retryafter; if [[ "$_retryafter" > 20 ]];then return 10; fi|g' lib/acme.sh
fi

mkdir -p ../ssl/
./lib/acme.sh --uninstall-cronjob
shopt -s expand_aliases
source ./lib/acme.sh.env
acme.sh --register-account -m my@example.com
systemctl reload hiddify-haproxy
