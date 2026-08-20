#!/bin/bash
set -e
cd /opt/hiddify-manager

mkdir -p /opt/hiddify-manager/data/ssl /opt/hiddify-manager/data/log/system
rm -f /opt/hiddify-manager/data/log/*.lock /opt/hiddify-manager/data/log/system/*.lock

chmod +x /opt/hiddify-manager/services/docker/systemctl /opt/hiddify-manager/services/docker/journalctl
cp /opt/hiddify-manager/services/docker/systemctl /usr/bin/systemctl
cp /opt/hiddify-manager/services/docker/journalctl /usr/bin/journalctl

echo "Defaults:hiddify-panel !requiretty" >/etc/sudoers.d/hiddify
echo "hiddify-panel ALL=(root) NOPASSWD: /opt/hiddify-manager/scripts/common/commander.py" >>/etc/sudoers.d/hiddify
chmod 440 /etc/sudoers.d/hiddify

# Check and set REDIS_URI_MAIN
if [ -z "$REDIS_URI_MAIN" ]; then
  if [ -z "$REDIS_PASSWORD" ]; then
    echo "One of the env variables REDIS_PASSWORD or REDIS_URI_MAIN must be set"
    exit 1
  fi
  export REDIS_URI_MAIN="redis://:${REDIS_PASSWORD}@redis:6379/0"
fi

# Check and set REDIS_URI_SSH
if [ -z "$REDIS_URI_SSH" ]; then
  if [ -z "$REDIS_PASSWORD" ]; then
    echo "One of the env variables REDIS_PASSWORD or REDIS_URI_SSH must be set"
    exit 1
  fi
  export REDIS_URI_SSH="redis://:${REDIS_PASSWORD}@redis:6379/1"
fi

# Check and set SQLALCHEMY_DATABASE_URI
if [ -z "$SQLALCHEMY_DATABASE_URI" ]; then
  if [ -z "$MYSQL_PASSWORD" ]; then
    echo "One of the env variables MYSQL_PASSWORD or SQLALCHEMY_DATABASE_URI must be set"
    exit 1
  fi
  export SQLALCHEMY_DATABASE_URI="mysql+mysqldb://hiddifypanel:${MYSQL_PASSWORD}@mariadb/hiddifypanel?charset=utf8mb4"
fi

wait_for_tcp() {
  local host="$1" port="$2" tries="${3:-60}"
  echo "Waiting for $host:$port ..."
  for _ in $(seq 1 "$tries"); do
    if python3 -c "import socket; socket.create_connection(('$host', $port), 2).close()" 2>/dev/null; then
      return 0
    fi
    sleep 2
  done
  echo "Timeout waiting for $host:$port" >&2
  return 1
}

wait_for_tcp mariadb 3306
wait_for_tcp redis 6379

DO_NOT_INSTALL=true /opt/hiddify-manager/scripts/install.sh docker --no-gui $@
/opt/hiddify-manager/scripts/status.sh --no-gui

echo Hiddify is started!!!! in 5 seconds you will see the system logs
sleep 5
tail -f /opt/hiddify-manager/data/log/system/*
