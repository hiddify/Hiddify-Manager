#!/bin/bash
rm -rf SUB_LINK HiddifyCli webui clash.db tmp VERSION
systemctl stop hiddify-cli.service > /dev/null 2>&1
systemctl disable hiddify-cli.service > /dev/null 2>&1
pkill HiddifyCli
fuser -k 6756/tcp
fuser -k 2334/tcp