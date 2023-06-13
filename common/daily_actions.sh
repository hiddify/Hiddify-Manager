#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

cd $( dirname -- "$0"; )


# systemctl restart systemd-journald
# sysctl -w vm.drop_caches=3