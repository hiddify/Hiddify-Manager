
MAIN_DOMAIN="$MAIN_DOMAIN;$SERVER_IP.sslip.io"
DOMAINS=${MAIN_DOMAIN//;/ }

kill -9 `lsof -t -i:80`

DST="../use-link"
echo "">$DST


echo -e "Permanent Admin link:  http://$SERVER_IP/$ADMIN_SECRET/ \n" >>$DST
echo -e "Secure Admin links: \n" >>$DST



for DOMAIN in $DOMAINS;	do
	echo -e "\thttps://$DOMAIN/$ADMIN_SECRET/\n" >>$DST

	DOMAIN_IP=$(dig +short -t a $DOMAIN.)
        

	echo "resolving domain $DOMAIN -> IP= $DOMAIN_IP ServerIP-> $SERVER_IP"
	if [[ $SERVER_IP != $DOMAIN_IP ]];then
			echo "maybe it is an error! make sure that it is correct"
			sleep 10
	fi


	if [[ ! -f $DOMAIN.key || ! -f $DOMAIN.crt ]];then
		openssl req -x509 -newkey rsa:2048 -keyout $DOMAIN.key -out $DOMAIN.crt -days 3650 -nodes -subj "/C=GB/ST=London/L=London/O=Google Trust Services LLC/CN=www.google.com"
	fi

	if [[ $(dig +short -t a $DOMAIN.) ]];then
		certbot certonly --standalone --http-01-port 80 --register-unsafely-without-email -d $DOMAIN --non-interactive --agree-tos --logs-dir $(pwd)/../log/system/
	fi
	if [[ -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem && -f /etc/letsencrypt/live/$DOMAIN/privkey.pem ]];then
		rm $DOMAIN.key $DOMAIN.crt
		ln -sf /etc/letsencrypt/live/$DOMAIN/fullchain.pem $DOMAIN.crt
		ln -sf /etc/letsencrypt/live/$DOMAIN/privkey.pem $DOMAIN.key
		
	fi
	chmod 644 $DOMAIN.key
done

if [[ "$FIRST_SETUP" == "true" ]];then
	echo -e "Please visit http://$SERVER_IP/ or https://$SERVER_IP.sslip.io/ in one hour to change your domain.">>$DST
	echo "or you can use the following links to continue setup:">>$DST
	echo  -e "\thttp://$SERVER_IP/$ADMIN_SECRET/config" >>$DST
	echo  -e "\thttps://$SERVER_IP.sslip.io/$ADMIN_SECRET/config" >>$DST
fi