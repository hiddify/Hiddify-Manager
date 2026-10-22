#!/bin/bash
# telemt hot-reloads users (ExecReload sends SIGHUP), but domain changes need a restart.
# Not running (e.g. it failed on an earlier config): start it with the new config; the try-* commands would skip it.
if ! systemctl is-active --quiet hiddify-telegram-proxy.service; then
    systemctl reset-failed hiddify-telegram-proxy.service 2>/dev/null
    systemctl start hiddify-telegram-proxy.service
elif [ "$1" = "domain" ]; then
    systemctl restart hiddify-telegram-proxy.service
else
    systemctl reload hiddify-telegram-proxy.service
fi
