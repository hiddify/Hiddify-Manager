#!/bin/bash
ln -sf "$(pwd)/hiddify-telegram-proxy.service" /etc/systemd/system/hiddify-telegram-proxy.service
systemctl enable hiddify-telegram-proxy.service
systemctl restart hiddify-telegram-proxy.service
# `systemctl status` is non-zero for some healthy transitional states; do not fail the step.
systemctl status hiddify-telegram-proxy --no-pager || true
