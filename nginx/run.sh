#!/bin/bash

source ../common/utils.sh
chown nginx -R .
set_folder_accessible_to_group .
chown nginx:hiddify-common parts/short-link.conf parts .

systemctl restart hiddify-nginx
systemctl start hiddify-nginx
