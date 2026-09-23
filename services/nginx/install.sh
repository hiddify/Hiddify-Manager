source /opt/hiddify-manager/scripts/common/utils.sh
if ! is_installed "nginx=1.30.*"; then
    useradd nginx
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    # lsb_release is missing on minimal images; an empty codename writes a
    # malformed list file that breaks every later `apt update`.
    DISTRO=$(. /etc/os-release && echo "$ID")
    CODENAME=$(. /etc/os-release && echo "${VERSION_CODENAME:-$UBUNTU_CODENAME}")
    [ -z "$CODENAME" ] && CODENAME=$(lsb_release -cs 2>/dev/null)
    [ "$DISTRO" = "debian" ] || DISTRO=ubuntu
    if [ -n "$CODENAME" ]; then
        echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/$DISTRO $CODENAME nginx" |
            sudo tee /etc/apt/sources.list.d/nginx.list
    else
        echo "Could not detect distro codename; skipping nginx.org repository"
        sudo rm -f /etc/apt/sources.list.d/nginx.list
    fi
    sudo apt update -y

fi
install_package "nginx=1.30.*"
usermod -aG hiddify-common nginx 2>/dev/null || true

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
