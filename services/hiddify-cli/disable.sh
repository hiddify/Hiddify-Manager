#!/bin/bash
rm -rf HiddifyCli webui clash.db tmp VERSION
systemctl stop hiddify-cli.service > /dev/null 2>&1
systemctl disable hiddify-cli.service > /dev/null 2>&1