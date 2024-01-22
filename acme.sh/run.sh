cd $( dirname -- "$0"; )
source ../common/utils.sh
source ./cert_utils.sh

# MAIN_DOMAIN="$MAIN_DOMAIN;$SERVER_IP.sslip.io"
DOMAINS=${MAIN_DOMAIN//;/ }

# echo -e "Permanent Admin link: \n   http://$SERVER_IP/$BASE_PROXY_PATH/$ADMIN_SECRET/admin/ \n" >>$DST
# echo -e "Secure Admin links: \n" >>$DST

for f in ../ssl/*.crt; do
	d=$(basename "$f" .crt)
	get_self_signed_cert $d
done

ssl_cert_path=../ssl
for file in "$ssl_cert_path"/*; do
	filename=$(basename "$file")
	if [[ ! " ${DOMAINS[*]} " =~ "${filename}" ]]; then
		echo "Removing $filename"
		rm "$file"
	fi
done
for DOMAIN in $DOMAINS; do
	get_cert $DOMAIN
done
# systemctl start hiddify-xray
systemctl reload hiddify-haproxy

for f in ../ssl/*.crt; do
	d=$(basename "$f" .crt)
	get_self_signed_cert $d
done

./lib/acme.sh --uninstall-cronjob
echo "" >/opt/hiddify-config/nginx/parts/acme.conf
systemctl reload hiddify-nginx
