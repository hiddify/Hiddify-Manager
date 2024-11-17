#!/bin/bash
cd $(dirname -- "$0")
source ../../common/utils.sh

if [ -z "$(ls -A data 2>/dev/null)" ];then
    mkdir -p data
    cp -R /var/lib/mysql/* data/
fi
chown -R mysql .

install_package mariadb-server

ln -sf $(pwd)/conf/maria.cnf "/etc/mysql/mariadb.conf.d/50-server.cnf"


sudo -u mysql mkdir -p /run/mysqld/






if [ "$MODE" != "install-docker" ];then

if [ ! -f "mysql_pass" ]; then
    echo "Generating a random password..."
    random_password=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c49; echo)
    echo "$random_password" >"mysql_pass"
    chmod 600 "mysql_pass"
    # Secure MariaDB installation
    sudo mysql_secure_installation <<EOF
y
$random_password
$random_password
y
y
y
y
EOF

    # Create user with localhost access
    sudo mysql -u root -f <<MYSQL_SCRIPT
CREATE USER 'hiddifypanel'@'localhost' IDENTIFIED BY '$random_password';
ALTER USER 'hiddifypanel'@'localhost' IDENTIFIED BY '$random_password';

GRANT ALL PRIVILEGES ON *.* TO 'hiddifypanel'@'localhost';
CREATE DATABASE hiddifypanel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;;
GRANT ALL PRIVILEGES ON hiddifypanel.* TO 'hiddifypanel'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
    
    echo "MariaDB setup complete."

systemctl restart mariadb    
fi
fi

systemctl start mariadb
