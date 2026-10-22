#!/bin/bash
# "users": only users changed and the panel already gave them to xray through its API (xray_api.py); the new
# config is for the next start. A restart here would drop every connection.
[ "$1" = "users" ] && exit 0
systemctl try-reload-or-restart hiddify-xray.service
