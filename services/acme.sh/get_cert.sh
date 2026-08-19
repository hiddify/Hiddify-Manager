#!/bin/bash
cd $(dirname -- "$0")
source cert_utils.sh
#./lib/acme.sh --register-account -m my@example.com

get_cert $1


echo "cert installation is done."
sleep 2
stop_nginx_acme
