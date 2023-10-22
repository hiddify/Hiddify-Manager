cd $(dirname -- "$0")
source ./lib/acme.sh.env

DOMAIN=$1
ssl_cert_path=../ssl
mkdir -p /opt/hiddify-manager/acme.sh/www/.well-known/acme-challenge
echo "location /.well-known/acme-challenge {root /opt/hiddify-manager/acme.sh/www/;}" >/opt/hiddify-manager/nginx/parts/acme.conf
systemctl reload --now hiddify-nginx

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

./lib/acme.sh --issue -w /opt/hiddify-manager/acme.sh/www/ -d $DOMAIN --log $(pwd)/../log/system/acme.log
./lib/acme.sh --issue -w /opt/hiddify-manager/acme.sh/www/ -d $DOMAIN --log $(pwd)/../log/system/acme.log --server letsencrypt

./lib/acme.sh --installcert -d $DOMAIN \
    --fullchainpath $ssl_cert_path/$DOMAIN.crt \
    --keypath $ssl_cert_path/$DOMAIN.crt.key \
    --reloadcmd "echo success"

if [[ $? != 0 ]]; then
    bash generate_self_signed_cert.sh $DOMAIN
fi

chmod 644 $ssl_cert_path/$DOMAIN.crt.key
echo "" >/opt/hiddify-manager/nginx/parts/acme.conf
systemctl reload --now hiddify-nginx

systemctl reload hiddify-haproxy
