#!/bin/bash
# Turning FakeTLS off must succeed even when units were never installed
# (otherwise run_parallel paints "FakeTLS Proxy" red on a healthy install).
systemctl stop hiddify-ss-v2ray.service >/dev/null 2>&1 || true
systemctl stop hiddify-ss-faketls.service >/dev/null 2>&1 || true

systemctl disable --now ss-v2ray.service >/dev/null 2>&1 || true
systemctl disable --now ss-faketls.service >/dev/null 2>&1 || true

systemctl disable --now hiddify-ss-v2ray.service >/dev/null 2>&1 || true
systemctl disable --now hiddify-ss-faketls.service >/dev/null 2>&1 || true
rm -f ss-faketls.service ss-faketls.service.* >/dev/null 2>&1 || true
exit 0
