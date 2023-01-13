apt-get install -y nginx
#  certbot python3-certbot-nginx python3-pip
# pip3 install pip pyopenssl --upgrade

# systemctl stop nginx
# pkill -9 nginx


# rm /etc/nginx/sites-available/default
# rm /etc/nginx/sites-enabled/default
# rm /etc/nginx/nginx.conf
# ln -sf $(pwd)/nginx.conf /etc/nginx/nginx.conf



# sed -i "s/listen 444 ssl;/listen 444 ssl http2;/" web.conf

ln -sf  $(pwd)/web.conf /etc/nginx/conf.d/web.conf
# mkdir -p /etc/nginx/stream.d/ 
# ln -sf $(pwd)/sni-proxy.conf /etc/nginx/stream.d/sni-proxy.conf
# ln -sf $(pwd)/signal.conf /etc/nginx/stream.d/signal.conf

# certbot certonly  --webroot -w $(pwd)/certbot --register-unsafely-without-email -d $MAIN_DOMAIN --non-interactive --agree-tos  --logs-dir $(pwd)/../log/system/certbot.log
# certbot --nginx --register-unsafely-without-email -d $MAIN_DOMAIN --non-interactive --agree-tos  --https-port 444 --no-redirect --logs-dir $(pwd)/../log/system/certbot.log
# if ! grep -Fxq "stream{include /etc/nginx/stream.d/*.conf;}" /etc/nginx/nginx.conf; then
#   echo "stream{include /etc/nginx/stream.d/*.conf;}">>/etc/nginx/nginx.conf;
# fi

