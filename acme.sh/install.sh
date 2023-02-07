sudo apt-get install socat
sudo apt-get uninstall certbot
mkdir -p /opt/hiddify-config/acme.sh/lib/
curl -L https://get.acme.sh| sh -s -- home /opt/hiddify-config/acme.sh/lib/ 
    

mkdir -p ../ssl/