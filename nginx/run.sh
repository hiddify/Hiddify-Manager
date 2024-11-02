#!/bin/bash
chmod -R 600 conf.d/
chmod -R 600 parts/
systemctl restart hiddify-nginx
systemctl start hiddify-nginx
