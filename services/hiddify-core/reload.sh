#!/bin/bash
if ! systemctl cat hiddify-core.service >/dev/null 2>&1; then
    echo "hiddify-core is not installed"
    exit 0
fi
rm /opt/hiddify-manager/data/hiddify-core/tor/lock 2>/dev/null || true
systemctl try-reload-or-restart hiddify-core.service
