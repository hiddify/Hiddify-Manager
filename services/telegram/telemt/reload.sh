#!/bin/bash
# telemt hot-reloads users (ExecReload sends SIGHUP), but domain changes need a restart.
if [ "$1" = "domain" ]; then
    systemctl try-restart hiddify-telegram-proxy.service
else
    systemctl try-reload-or-restart hiddify-telegram-proxy.service
fi
