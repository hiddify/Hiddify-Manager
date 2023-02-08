sudo apt-get install socat
sudo apt-get uninstall certbot
rm -rf /opt/hiddify/
if [ ! -d lib ];then
    mkdir -p /opt/hiddify-config/acme.sh/lib/
    curl -L https://get.acme.sh| sh -s -- home /opt/hiddify-config/acme.sh/lib/
fi

./lib/acme.sh --register-account -m my@example.com

mkdir -p ../ssl/