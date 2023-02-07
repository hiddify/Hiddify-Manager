
# MAIN_DOMAIN="$MAIN_DOMAIN;$SERVER_IP.sslip.io"
DOMAINS=${MAIN_DOMAIN//;/ }

kill -9 `lsof -t -i:80`

DST="../use-link"
echo "">$DST


echo -e "Permanent Admin link: \n   http://$SERVER_IP/$BASE_PROXY_PATH/$ADMIN_SECRET/admin/ \n" >>$DST
echo -e "Secure Admin links: \n" >>$DST

ssl_cert_path=../ssl/

for DOMAIN in $DOMAINS;	do
	echo -e "   https://$DOMAIN/$BASE_PROXY_PATH/$ADMIN_SECRET/admin/\n" >>$DST

	DOMAIN_IP=$(dig +short -t a $DOMAIN.)
        

	echo "resolving domain $DOMAIN -> IP= $DOMAIN_IP ServerIP-> $SERVER_IP"
	if [[ $SERVER_IP != $DOMAIN_IP ]];then
			echo "maybe it is an error! make sure that it is correct"
			sleep 10
	fi


	if [[ ! -f $ssl_cert_path/$DOMAIN.key || ! -f $ssl_cert_path/$DOMAIN.crt ]];then
		rm $ssl_cert_path/$DOMAIN.key $ssl_cert_path/$DOMAIN.crt
		openssl req -x509 -newkey rsa:2048 -keyout $ssl_cert_path/$DOMAIN.key -out $ssl_cert_path/$DOMAIN.crt -days 3650 -nodes -subj "/C=GB/ST=London/L=London/O=Google Trust Services LLC/CN=www.google.com"
	fi

	if [[ $(dig +short -t a $DOMAIN.) ]];then
		
	fi
	certbot certonly --standalone --http-01-port 80 --register-unsafely-without-email -d $DOMAIN --non-interactive --agree-tos --logs-dir $(pwd)/../log/system/
	
	if [[ -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem && -f /etc/letsencrypt/live/$DOMAIN/privkey.pem ]];then
		rm $ssl_cert_path/$DOMAIN.key $ssl_cert_path/$DOMAIN.crt
		ln -sf /etc/letsencrypt/live/$DOMAIN/fullchain.pem $ssl_cert_path/$DOMAIN.crt
		ln -sf /etc/letsencrypt/live/$DOMAIN/privkey.pem $ssl_cert_path/$DOMAIN.key
		
	fi
	chmod 644 $ssl_cert_path/$DOMAIN.key
done

if [[ "$FIRST_SETUP" == "true" ]];then
	echo -e "Please visit http://$SERVER_IP/ or https://$SERVER_IP.sslip.io/ in one hour to change your domain.">>$DST
	echo "or you can use the following links to continue setup:">>$DST
	echo  -e "   http://$SERVER_IP/$BASE_PROXY_PATH/$ADMIN_SECRET/admin/quick-setup/" >>$DST
	echo  -e "   https://$SERVER_IP.sslip.io/$BASE_PROXY_PATH/$ADMIN_SECRET/admin/quick-setup/" >>$DST
fi