#!/bin/bash
set -e

mkdir -p /opt/hiddify-manager/data/cert /opt/hiddify-manager/data/log


chmod +x /opt/hiddify-manager/services/docker/systemctl /opt/hiddify-manager/services/docker/journalctl 
cp /opt/hiddify-manager/services/docker/systemctl /usr/bin/systemctl 
cp /opt/hiddify-manager/services/docker/journalctl /usr/bin/journalctl 


# Build URIs from passwords when only passwords are set (installer / custom .env).
if [ -z "${REDIS_URI_MAIN:-}" ] && [ -n "${REDIS_PASSWORD:-}" ]; then
    export REDIS_URI_MAIN="redis://:${REDIS_PASSWORD}@127.0.0.1:6379/1"
fi
if [ -z "${SQLALCHEMY_DATABASE_URI:-}" ] && [ -n "${MYSQL_PASSWORD:-}" ]; then
    export SQLALCHEMY_DATABASE_URI="mysql+mysqldb://hiddifypanel:${MYSQL_PASSWORD}@127.0.0.1:3306/hiddifypanel?charset=utf8mb4"
fi

if [ -z "${REDIS_URI_MAIN:-}" ]; then
    echo "env variables REDIS_URI_MAIN (or REDIS_PASSWORD) must be set"
    exit 1
fi

if [ -z "${SQLALCHEMY_DATABASE_URI:-}" ]; then
    echo "env variables SQLALCHEMY_DATABASE_URI (or MYSQL_PASSWORD) must be set"
    exit 1
fi

source .venv313/bin/activate
# The image has the UI built; a source tree mounted over it (docker-compose.override)
# must bring its own: build it on the host, the container has no Node.js.
if [ ! -f services/panel/src/hiddifypanel/static/admin-v2/index.html ] ||
   [ ! -f services/panel/src/hiddifypanel/static/user-front/manifest.json ]; then
    echo "WARNING: panel UIs are not built in the mounted panel source. On the host run:"
    echo "    make ui"
    echo "  (or: cd services/panel/src && make build-ui)"
fi
uv pip install -e services/panel/src 

DO_NOT_INSTALL=true /opt/hiddify-manager/scripts/install.sh docker --no-gui $@
/opt/hiddify-manager/scripts/status.sh --no-gui

echo Hiddify is started!!!! in 5 seconds you will see the system logs
hiddify admin
sleep 5
tail -f /opt/hiddify-manager/data/log/*
