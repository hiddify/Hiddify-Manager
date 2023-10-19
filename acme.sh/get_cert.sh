cd $(dirname -- "$0")
source ./lib/acme.sh.env

DOMAIN=$1
ssl_cert_path=../ssl
mkdir -p /opt/hiddify-manager/acme.sh/www/.well-known/acme-challenge
echo "location /.well-known/acme-challenge {root /opt/hiddify-manager/acme.sh/www/;}" >/opt/hiddify-manager/nginx/parts/acme.conf
systemctl reload hiddify-nginx
rm -f $ssl_cert_path/$DOMAIN.key
DOMAIN_IP=$(dig +short -t a $DOMAIN.)
echo "resolving domain $DOMAIN -> IP= $DOMAIN_IP ServerIP-> $SERVER_IP"
if [[ $SERVER_IP != $DOMAIN_IP ]]; then
    echo "maybe it is an error! make sure that it is correct"
    #sleep 10
fi

flags=
if [ "$SERVER_IPv6" != "" ]; then
    flags="--listen-v6"
fi

./lib/acme.sh --issue -w /opt/hiddify-manager/acme.sh/www/ -d $DOMAIN --log $(pwd)/../log/system/acme.log --server letsencrypt
./lib/acme.sh --issue -w /opt/hiddify-manager/acme.sh/www/ -d $DOMAIN --log $(pwd)/../log/system/acme.log

./lib/acme.sh --installcert -d $DOMAIN \
    --fullchainpath $ssl_cert_path/$DOMAIN.crt \
    --keypath $ssl_cert_path/$DOMAIN.crt.key \
    --reloadcmd "echo success"

if [[ $? != 0 ]]; then
    rm $ssl_cert_path/$DOMAIN.key $ssl_cert_path/$DOMAIN.crt
    openssl req -x509 -newkey rsa:2048 -keyout $ssl_cert_path/$DOMAIN.crt.key -out $ssl_cert_path/$DOMAIN.crt -days 3650 -nodes -subj "/C=GB/ST=London/L=London/O=Google Trust Services LLC/CN=www.google.com"
fi

chmod 644 $ssl_cert_path/$DOMAIN.crt.key
echo "" >/opt/hiddify-manager/nginx/parts/acme.conf
systemctl reload hiddify-nginx

systemctl reload hiddify-haproxy
