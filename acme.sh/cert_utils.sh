function get_cert() {
    cd /opt/hiddify-manager
    source ./lib/acme.sh.env
    DOMAIN=$1
    ssl_cert_path=../ssl
    mkdir -p /opt/hiddify-manager/acme.sh/www/.well-known/acme-challenge
    echo "location /.well-known/acme-challenge {root /opt/hiddify-manager/acme.sh/www/;}" >/opt/hiddify-manager/nginx/parts/acme.conf
    # systemctl reload --now hiddify-nginx

    rm -f $ssl_cert_path/$DOMAIN.key
    DOMAIN_IP=$(dig +short -t a $DOMAIN.)
    echo "resolving domain $DOMAIN -> IP= $DOMAIN_IP ServerIP-> $SERVER_IP"
    if [[ $SERVER_IP != $DOMAIN_IP ]]; then
        echo "maybe it is an error! make sure that it is correct"
        #sleep 10
    fi

    flags=
    if [ "$SERVER_IPv6" != "" ]; then
        flags="--listen-v6"
    fi

    ./lib/acme.sh --issue -w /opt/hiddify-manager/acme.sh/www/ -d $DOMAIN --log $(pwd)/../log/system/acme.log --pre-hook "systemctl restart hiddify-nginx"
    # ./lib/acme.sh --issue -w /opt/hiddify-manager/acme.sh/www/ -d $DOMAIN --log $(pwd)/../log/system/acme.log --server letsencrypt

    ./lib/acme.sh --installcert -d $DOMAIN \
        --fullchainpath $ssl_cert_path/$DOMAIN.crt \
        --keypath $ssl_cert_path/$DOMAIN.crt.key \
        --reloadcmd "echo success"

    if [[ $? != 0 ]]; then
        bash generate_self_signed_cert.sh $DOMAIN
    fi

    chmod 644 $ssl_cert_path/$DOMAIN.crt.key
    echo "" >/opt/hiddify-manager/nginx/parts/acme.conf
    systemctl reload --now hiddify-nginx

    systemctl reload hiddify-haproxy
}

function get_self_signed_cert() {
    cd /opt/hiddify-manager
    d=$1
    mkdir -p ../ssl
    certificate="../ssl/$d.crt"
    private_key="../ssl/$d.crt.key"
    current_date=$(date +%s)
    generate_new_cert=0
    # Check if the certificate file exists
    if [ ! -f "$certificate" ]; then
        echo "Certificate file not found. Generating a new certificate."
        generate_new_cert=1
    else
        expire_date=$(openssl x509 -enddate -noout -in "$certificate" | cut -d= -f2-)
        # Convert the expire date to seconds since epoch
        expire_date_seconds=$(date -d "$expire_date" +%s)

        if [ "$current_date" -ge "$expire_date_seconds" ]; then
            echo "Certificate is expired. Generating a new certificate."
            generate_new_cert=1
        fi
    fi

    # Check if the private key file exists
    if [ ! -f "$private_key" ]; then
        echo "Private key file not found. Generating a new certificate."
        generate_new_cert=1
    else
        # Check if the private key is valid
        if ! openssl rsa -check -in "$private_key"; then
            echo "Private key is invalid. Generating a new certificate."
            generate_new_cert=1
        fi
    fi

    # Generate a new certificate if necessary
    if [ "$generate_new_cert" -eq 1 ]; then
        openssl req -x509 -newkey rsa:2048 -keyout "$private_key" -out "$certificate" -days 3650 -nodes -subj "/C=GB/ST=London/L=London/O=Google Trust Services LLC/CN=$d"
        echo "New certificate and private key generated."
    fi

}
