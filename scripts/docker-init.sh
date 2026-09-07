#!/bin/bash
set -e

mkdir -p /opt/hiddify-manager/data/ssl /opt/hiddify-manager/data/log/system
rm -f /opt/hiddify-manager/data/log/*.lock /opt/hiddify-manager/data/log/system/*.lock





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


DO_NOT_INSTALL=true /opt/hiddify-manager/scripts/install.sh docker --no-gui $@
/opt/hiddify-manager/scripts/status.sh --no-gui

echo Hiddify is started!!!! in 5 seconds you will see the system logs
hiddify admin
sleep 5
tail -f /opt/hiddify-manager/data/log/system/*
