echo "nginx install.sh $*"

# USER_SECRET=$1
# DOMAIN=$2
# IP=$(curl -Lso- https://api.ipify.org);
# echo $IP
# guid="${1:0:8}-${1:8:4}-${1:12:4}-${1:16:4}-${1:20:12}"
# cloudprovider=${4:-$DOMAIN}

if [[ "$ENABLE_SPEED_TEST" == "true" ]];then
	ln -s $(pwd)/speedtest.conf /etc/nginx/conf.d/speedtest.conf
else
	rm /etc/nginx/conf.d/speedtest.conf
fi

pkill nginx


pkill -9 nginx
certbot --nginx --register-unsafely-without-email -d $MAIN_DOMAIN --non-interactive --agree-tos  --https-port 444 --no-redirect
pkill -9 nginx
echo -e "Please visit http://$SERVER_IP/ in one hour to change your domain.\n\n  Proxy Link is:\n https://$MAIN_DOMAIN/$USER_SECRET/ \n\n Alias to admin Link is:\n http://$SERVER_IP/$ADMIN_SECRET/ \n\n Current Admin Link is:\n https://$MAIN_DOMAIN/$ADMIN_SECRET/">use-link

systemctl restart nginx
