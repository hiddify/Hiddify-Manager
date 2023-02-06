#!/bin/bash
cd $( dirname -- "$0"; )
PORT= $1 || 9001

iptables -I INPUT -p tcp --dport $PORT -j ACCEPT

echo "kill $(lsof -t -i:$PORT)"| at now + 4 hour
echo "iptables -D INPUT -p tcp --dport $PORT -j ACCEPT" | at now + 4 hour

gunicorn -b 0.0.0.0:$PORT 'hiddifypanel:create_app()' &


