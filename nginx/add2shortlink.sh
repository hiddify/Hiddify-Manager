#!/bin/bash
cd $( dirname -- "$0"; )
real_url=$1
short_code=$2
min=$3
item="location ~* ^/$short_code(/)?$ {return 302 $real_url;}"
echo $item
echo $item>>./parts/short-link.conf
echo "sed -i '/\/$short_code(/d' ./parts/short-link.conf"| at now + $min min
systemctl reload hiddify-nginx.service
