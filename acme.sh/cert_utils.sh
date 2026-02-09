#!/usr/bin/env bash

restricted_tlds=("af" "by" "cu" "er" "gn" "ir" "kp" "lr" "ru" "ss" "su" "sy" "zw" "amazonaws.com" "azurewebsites.net" "cloudapp.net")

shopt -s expand_aliases

source ./lib/acme.sh.env
source ../common/utils.sh

isipv4() {
  [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

isipv6() {
  [[ $1 =~ ^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$ ]]
}

is_ok_domain_zerossl() {
    local domain="$1"
    for tld in "${restricted_tlds[@]}"; do
        [[ "$domain" == *.$tld ]] && return 1
    done
    return 0
}

get_cert() {
    cd /opt/hiddify-manager/acme.sh/ || exit 1
    source ./lib/acme.sh.env

    DOMAIN="$1"
    ssl_cert_path="/opt/hiddify-manager/ssl"

    # ---------- IP FLOW ----------
    if isipv4 "$DOMAIN" || isipv6 "$DOMAIN"; then
        echo "IP detected → using self-signed certificate"
        bash generate_self_signed_cert.sh "$DOMAIN"
        return
    fi

    # ---------- DOMAIN FLOW (from 11.0.13) ----------
    rm -f "$ssl_cert_path/$DOMAIN.key"

    if [ ${#DOMAIN} -le 64 ]; then
        mkdir -p /opt/hiddify-manager/acme.sh/www/.well-known/acme-challenge
        echo "location /.well-known/acme-challenge {root /opt/hiddify-manager/acme.sh/www/;}" \
            >/opt/hiddify-manager/nginx/parts/acme.conf

        DOMAIN_IP=$(dig +short -t a "$DOMAIN.")
        DOMAIN_IPv6=$(dig +short -t aaaa "$DOMAIN.")

        echo "resolving domain $DOMAIN : IP=$DOMAIN_IP IPv6=$DOMAIN_IPv6"

        acme.sh --issue \
            -w /opt/hiddify-manager/acme.sh/www/ \
            -d "$DOMAIN" \
            --log /opt/hiddify-manager/log/system/acme.log \
            --server letsencrypt \
            --pre-hook "systemctl restart hiddify-nginx"

        if is_ok_domain_zerossl "$DOMAIN"; then
            acme.sh --issue \
                -w /opt/hiddify-manager/acme.sh/www/ \
                -d "$DOMAIN" \
                --log /opt/hiddify-manager/log/system/acme.log \
                --pre-hook "systemctl restart hiddify-nginx"
        fi

        cp "$ssl_cert_path/$DOMAIN.crt" "$ssl_cert_path/$DOMAIN.crt.bk" 2>/dev/null
        cp "$ssl_cert_path/$DOMAIN.crt.key" "$ssl_cert_path/$DOMAIN.crt.key.bk" 2>/dev/null

        acme.sh --installcert -d "$DOMAIN" \
            --fullchainpath "$ssl_cert_path/$DOMAIN.crt" \
            --keypath "$ssl_cert_path/$DOMAIN.crt.key" \
            --reloadcmd "echo success"

        err=$?
        if [ "$err" = 0 ]; then
            rm -f "$ssl_cert_path/$DOMAIN.crt.bk"
            rm -f "$ssl_cert_path/$DOMAIN.crt.key.bk"
        else
            mv "$ssl_cert_path/$DOMAIN.crt.key.bk" "$ssl_cert_path/$DOMAIN.crt.key"
            mv "$ssl_cert_path/$DOMAIN.crt.bk" "$ssl_cert_path/$DOMAIN.crt"
        fi
    else
        err=1
    fi

    if [[ "$err" != 0 ]]; then
        bash generate_self_signed_cert.sh "$DOMAIN"
    fi

    chmod 600 "$ssl_cert_path/$DOMAIN.crt.key"
    chmod 600 -R "$ssl_cert_path"

    echo "" >/opt/hiddify-manager/nginx/parts/acme.conf

    systemctl reload hiddify-nginx
    systemctl reload hiddify-haproxy
}
