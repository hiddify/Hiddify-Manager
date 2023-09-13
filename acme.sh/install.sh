source ../common/utils.sh

install_package socat
remove_package certbot

mkdir -p /opt/hiddify-server/acme.sh/lib/
if ! is_installed ./lib/acme.sh; then
    curl -L https://get.acme.sh | sh -s -- home /opt/hiddify-server/acme.sh/lib \
        --config-home /opt/hiddify-server/acme.sh/lib/data \
        --cert-home /opt/hiddify-server/acme.sh/lib/certs

    sed -i 's|_sleep_overload_retry_sec=$_retryafter|_sleep_overload_retry_sec=$_retryafter; if [[ "$_retryafter" > 20 ]];then return 10; fi|g' lib/acme.sh
    ./lib/acme.sh --register-account -m my@example.com
    ./lib/acme.sh --uninstall-cronjob
fi
mkdir -p ../ssl/
