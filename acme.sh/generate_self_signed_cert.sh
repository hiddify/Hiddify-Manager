cd $(dirname -- "$0")
source cert_utils.sh
get_self_signed_cert $1
