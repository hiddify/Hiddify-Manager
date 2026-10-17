#!/bin/bash
set -e

mkdir -p /opt/hiddify-manager/data/cert /opt/hiddify-manager/data/log/system
rm -f /opt/hiddify-manager/data/log/*.lock /opt/hiddify-manager/data/log/system/*.lock


chmod +x /opt/hiddify-manager/services/docker/systemctl /opt/hiddify-manager/services/docker/journalctl 
cp /opt/hiddify-manager/services/docker/systemctl /usr/bin/systemctl 
cp /opt/hiddify-manager/services/docker/journalctl /usr/bin/journalctl 


# Check and set REDIS_URI_MAIN
if [ -z "$REDIS_URI_MAIN" ]; then
    echo "env variables REDIS_URI_MAIN must be set"
    exit 1
 
fi


# Check and set SQLALCHEMY_DATABASE_URI
if [ -z "$SQLALCHEMY_DATABASE_URI" ]; then
    echo "env variables SQLALCHEMY_DATABASE_URI must be set"
    exit 1
 
fi

source .venv313/bin/activate
# The image has the UI built; a source tree mounted over it (docker-compose.override)
# must bring its own: build it on the host, the container has no Node.js.
if [ ! -f services/panel/src/hiddifypanel/static/admin-v2/index.html ]; then
    echo "WARNING: admin UI is not built in the mounted panel source. On the host run:"
    echo "    cd services/panel/src/hiddifypanel/admin_v2 && npm ci && npm run build"
fi
uv pip install -e services/panel/src 

DO_NOT_INSTALL=true /opt/hiddify-manager/scripts/install.sh docker --no-gui $@
/opt/hiddify-manager/scripts/status.sh --no-gui

echo Hiddify is started!!!! in 5 seconds you will see the system logs
hiddify admin
sleep 5
tail -f /opt/hiddify-manager/data/log/system/*
