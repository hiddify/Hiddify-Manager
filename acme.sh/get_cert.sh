#!/bin/bash
cd $(dirname -- "$0")
source cert_utils.sh
#./lib/acme.sh --register-account -m my@example.com
get_cert $1
