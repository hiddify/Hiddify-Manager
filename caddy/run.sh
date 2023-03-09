ln -sf $(pwd)/Caddyfile /etc/caddy/Caddyfile




systemctl reload caddy
systemctl start caddy