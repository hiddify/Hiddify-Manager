sudo apt-get install socat
sudo apt-get remove -y certbot
rm -rf /opt/hiddify/

    mkdir -p /opt/hiddify-config/acme.sh/lib/
    curl -L https://get.acme.sh| sh -s -- home /opt/hiddify-config/acme.sh/lib \
     --config-home /opt/hiddify-config/acme.sh/lib/data \
     --cert-home  /opt/hiddify-config/acme.sh/lib/certs



mkdir -p ../ssl/