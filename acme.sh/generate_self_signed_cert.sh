#!/bin/bash
cd $(dirname -- "$0")
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
