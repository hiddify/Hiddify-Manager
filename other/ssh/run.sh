

sed -i "s/:2222/:$ssh_server_port" .env

systemctl restart hiddify-ssh-liberty-bridge