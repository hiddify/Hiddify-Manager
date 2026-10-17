mkdir -p /opt/hiddify-manager/data/services/acme.sh/www/.well-known/acme-challenge
echo "location /.well-known/acme-challenge {root /opt/hiddify-manager/data/services/acme.sh/www/;}" >/opt/hiddify-manager/data/services/nginx/parts/acme.conf
chown -R nginx /opt/hiddify-manager/data/services/acme.sh/www/

systemctl restart hiddify-nginx