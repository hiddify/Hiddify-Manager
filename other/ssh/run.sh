

#sed -i "s/:2222/:$ssh_server_port/g" .env
ln -sf $(pwd)/hiddify-ssh-liberty-bridge.service /etc/systemd/system/hiddify-ssh-liberty-bridge.service

chown -R liberty-bridge host_key
chmod 600 .env*

systemctl enable hiddify-ssh-liberty-bridge
systemctl restart hiddify-ssh-liberty-bridge