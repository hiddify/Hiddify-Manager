#!/bin/bash

mkdir /hiddify-data/ssl/
./apply_configs.sh --no-gui
./status.sh --no-gui

echo Hiddify is started!!!! in 5 seconds you will see the system logs
sleep 5
tail -f /opt/hiddify-manager/log/system/*