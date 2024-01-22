cd $(dirname -- "$0")
source ../common/utils.sh
install_package socat
remove_package certbot

mkdir -p ./lib/
if ! is_installed ./lib/acme.sh; then
    curl -L https://get.acme.sh | sh -s -- home /opt/hiddify-config/acme.sh/lib \
        --config-home /opt/hiddify-config/acme.sh/lib/data \
        --cert-home /opt/hiddify-config/acme.sh/lib/certs --nocron

    sed -i 's|_sleep_overload_retry_sec=$_retryafter|_sleep_overload_retry_sec=$_retryafter; if [[ "$_retryafter" > 20 ]];then return 10; fi|g' lib/acme.sh
fi

mkdir -p ../ssl/
./lib/acme.sh --uninstall-cronjob
source lib/acme.sh.env
acme.sh --register-account -m my@example.com
systemctl reload hiddify-haproxy
