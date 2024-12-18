source ../common/utils.sh
if ! is_installed "nginx=1.26.*"; then
    useradd nginx
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor |
        sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
    http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" |
        sudo tee /etc/apt/sources.list.d/nginx.list
    sudo apt update -y

fi
install_package "nginx=1.26.*"

systemctl kill nginx >/dev/null 2>&1
systemctl disable nginx >/dev/null 2>&1
systemctl kill apache2 >/dev/null 2>&1
systemctl disable apache2 >/dev/null 2>&1
# pkill -9 nginx

rm /etc/nginx/conf.d/web.conf >/dev/null 2>&1
rm /etc/nginx/sites-available/default >/dev/null 2>&1
rm /etc/nginx/sites-enabled/default >/dev/null 2>&1
rm /etc/nginx/conf.d/default.conf >/dev/null 2>&1
rm /etc/nginx/conf.d/xray-base.conf >/dev/null 2>&1
rm /etc/nginx/conf.d/speedtest.conf >/dev/null 2>&1

mkdir -p run
ln -sf $(pwd)/hiddify-nginx.service /etc/systemd/system/hiddify-nginx.service
systemctl enable hiddify-nginx.service
