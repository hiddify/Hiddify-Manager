#!/bin/bash
cd $( dirname -- "$0"; )
real_url=$1
short_code=$2
min=$3
item="location ~* ^/$short_code(/)?$ {return 302 $real_url;}"
echo $item
SHORT_LINK_CONF=/opt/hiddify-manager/data/services/nginx/parts/short-link.conf
echo $item>>$SHORT_LINK_CONF
echo "sed -i '/\/$short_code(/d' $SHORT_LINK_CONF"| at now + $min min
systemctl reload hiddify-nginx.service
