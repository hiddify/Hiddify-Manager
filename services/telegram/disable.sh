#!/bin/bash
# Turning Telegram proxy off must succeed when units were never installed
# (otherwise run_parallel paints "Telegram Proxy" red on a healthy install).
systemctl stop hiddify-telegram-proxy >/dev/null 2>&1 || true
systemctl disable hiddify-telegram-proxy >/dev/null 2>&1 || true
# Old unit names (the service was called mtproxy before)
systemctl disable --now mtproxy >/dev/null 2>&1 || true
rm -f /etc/systemd/system/mtproxy.service
systemctl stop mtproto-proxy >/dev/null 2>&1 || true
systemctl disable mtproto-proxy >/dev/null 2>&1 || true
exit 0
