cp Caddyfile.template Caddyfile
CDOMAINS="${MAIN_DOMAIN/;/, }" 

sed -i "s|%DOMAINS%|$CDOMAINS|g" Caddyfile
sed -i "s|%PROXY_PATH%|$BASE_PROXY_PATH|g" Caddyfile
sed -i "s|%DECOY_DOMAIN%|$DECOY_DOMAIN|g" Caddyfile

ln -sf $(pwd)/Caddyfile /etc/caddy/Caddyfile




systemctl reload caddy
systemctl start caddy