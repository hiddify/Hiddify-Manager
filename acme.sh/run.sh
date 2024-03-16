source ../common/utils.sh
source ./cert_utils.sh

set_domains_vars_from_hpanel

for d in $DOMAINS; do
    get_cert $d
done


for d in $FAKE_DOMAINS; do
    get_self_signed_cert $d
done

for f in ../ssl/*.crt; do
    d=$(basename "$f" .crt)
    get_self_signed_cert $d
done
systemctl reload hiddify-haproxy