#!/bin/bash

source /opt/hiddify-manager/scripts/common/utils.sh
mkdir -p /opt/hiddify-manager/data/services/nginx/parts
touch /opt/hiddify-manager/data/services/nginx/parts/short-link.conf
touch /opt/hiddify-manager/data/services/nginx/parts/acme.conf
chown nginx -R /opt/hiddify-manager/data/services/nginx
mkdir -p /opt/hiddify-manager/services/nginx/run
chown nginx /opt/hiddify-manager/services/nginx/run
set_files_in_folder_readable_to_hiddify_common_group /opt/hiddify-manager/data/services/nginx/parts/short-link.conf
chmod g+w /opt/hiddify-manager/data/services/nginx/parts/short-link.conf

systemctl daemon-reload
systemctl restart hiddify-nginx
systemctl start hiddify-nginx
