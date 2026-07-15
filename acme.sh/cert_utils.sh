restricted_tlds=("af" "by" "cu" "er" "gn" "ir" "kp" "lr" "ru" "ss" "su" "sy" "zw" "amazonaws.com","azurewebsites.net","cloudapp.net")
shopt -s expand_aliases

source ./lib/acme.sh.env
source ../common/utils.sh
# Function to check if a domain is restricted
is_ok_domain_zerossl() {
    domain="$1"
    for tld in "${restricted_tlds[@]}"; do
        if [[ $domain == *.$tld ]]; then
            return 1 # Domain is restricted
        fi
        
    done
    return 0 # Domain is not restricted
}
isipv4() {
  [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  IFS='.' read -r a b c d <<< "$1"
  for o in $a $b $c $d; do
    (( o >= 0 && o <= 255 )) || return 1
  done
  return 0
}

isipv6() {
  [[ $1 =~ ^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$ ]]
}
acmecmd() {
    acme.sh --issue \
        -w /opt/hiddify-manager/acme.sh/www/ \
        --log /opt/hiddify-manager/log/system/acme.log \
        --pre-hook "bash /opt/hiddify-manager/acme.sh/prepare_acme.sh" \
        --post-hook "hiddify-panel-cli sync-tls-store -d $2" \
        "$@"
}


stop_nginx_acme(){
    echo "" >/opt/hiddify-manager/nginx/parts/acme.conf
    systemctl reload --now hiddify-nginx
    systemctl reload hiddify-haproxy
}


function get_cert() {
    cd /opt/hiddify-manager/acme.sh/
    source ./lib/acme.sh.env
    # ./lib/acme.sh --register-account -m my@example.com

    DOMAIN=$1
    ssl_cert_path=/opt/hiddify-manager/ssl
    rm -f $ssl_cert_path/$DOMAIN.key

    if [ ${#DOMAIN} -le 64 ]; then
        
        

        DOMAIN_IP=$(dig +short -t a $DOMAIN.)
        DOMAIN_IPv6=$(dig +short -t aaaa $DOMAIN.)
        echo "resolving domain $DOMAIN : IP=$DOMAIN_IP IPv6=$DOMAIN_IPv6   ServerIP=$SERVER_IP ServerIPv6=$SERVER_IPv6"
        if [[ "$SERVER_IP" == "" || $SERVER_IP != $DOMAIN_IP ]] && [[ "$SERVER_IPv6" == "" || $SERVER_IPv6 != $DOMAIN_IPv6 ]]; then
            error "maybe it is an error! make sure that it is correct"
            #sleep 10
        fi

        flags=
        # if [ "$SERVER_IPv6" != "" ]; then
        #     flags="--listen-v6"
        # fi
        
        if isipv4 "$DOMAIN"; then
            acmecmd -d $DOMAIN --server letsencrypt --certificate-profile shortlived --days 6 
        elif isipv6 "$DOMAIN"; then
            acmecmd -d [$DOMAIN] --server letsencrypt --certificate-profile shortlived --days 6 --listen-v6
        else
            acmecmd -d "$DOMAIN" --server letsencrypt
            if [ "$?" -ne 0 ] && is_ok_domain_zerossl "$DOMAIN"; then
                acmecmd -d "$DOMAIN" --server zerossl
            fi

        fi
        
        acme.sh --installcert -d $DOMAIN \
            --fullchainpath $ssl_cert_path/$DOMAIN.crt \
            --keypath $ssl_cert_path/$DOMAIN.crt.key \
            --reloadcmd "echo success"
        
        err=$?
        
    else
        err=1
    fi

    if [[ $err != 0 ]]; then
        get_self_signed_cert $DOMAIN  #it will check the certificate if is valid it will not create 
    
    fi

    chmod 600 $ssl_cert_path/$DOMAIN.crt.key
    chmod 600 -R $ssl_cert_path
}


function get_self_signed_cert() {
    cd /opt/hiddify-manager/acme.sh/
    local d=$1
    if [ ${#d} -gt 64 ]; then
        echo "Domain length exceeds 64 characters. Truncating to the first 64 characters."
        d="${d:0:64}"
    fi
    mkdir -p /opt/hiddify-manager/ssl
    local certificate="/opt/hiddify-manager/ssl/$d.crt"
    local private_key="/opt/hiddify-manager/ssl/$d.crt.key"
    local current_date=$(date +%s)
    local generate_new_cert=0
    # Check if the certificate file exists
    if [ ! -f "$certificate" ]; then
        echo "Certificate $d ($certificate) file not found. Generating a new certificate."
        generate_new_cert=1
    else
        local expire_date=$(openssl x509 -enddate -noout -in "$certificate" | cut -d= -f2-)
        # Convert the expire date to seconds since epoch
        local expire_date_seconds=$(date -d "$expire_date" +%s)

        if [ "$current_date" -ge "$expire_date_seconds" ]; then
            echo "Certificate $d ($certificate) is expired. Generating a new certificate."
            generate_new_cert=1
        fi
    fi

    # Check if the private key file exists
    if [ ! -f "$private_key" ]; then
        echo "Private key file $d ($private_key) not found. Generating a new certificate."
        generate_new_cert=1
    else
        # Check if the private key is valid
        if ! openssl rsa -check -in "$private_key" >/dev/null && ! openssl ec -check -in "$private_key" >/dev/null; then
            echo "Private key $d ($private_key) is invalid. Generating a new certificate."
            generate_new_cert=1
        fi
    fi

    # Generate a new certificate if necessary
    if [ "$generate_new_cert" -eq 1 ]; then
        openssl req -x509 -newkey rsa:2048 -keyout "$private_key" -out "$certificate" -days 3650 -nodes -subj "/C=GB/ST=London/L=London/O=Google Trust Services LLC/CN=$d"
        echo "New certificate and private key generated."
        hiddify-panel-cli sync-tls-store -d "$d"
    fi
    chmod 600 -R $private_key

}
