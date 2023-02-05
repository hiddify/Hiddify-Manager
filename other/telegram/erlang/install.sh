echo "telegram proxy install.sh $*"
systemctl stop mtproxy.service
systemctl disable mtproxy.service

# apt install -y python3 python3-uvloop python3-cryptography python3-socks libcap2-bin
# useradd --no-create-home -s /usr/sbin/nologin tgproxy

# git clone https://github.com/alexbers/mtprotoproxy 
# cd  mtprotoproxy
# sed "s/00000000000000000000000000000001/defaultusersecret/g" config.py > config.py.template
# echo 'AD_TAG="TELEGRAM_AD_TAG"'>>config.py.template
# echo 'TLS_DOMAIN = "TELEGRAM_FAKE_TLS_DOMAIN"'>> config.py.template
# sed -i 's/PORT = 443/PORT = 1001/g' config.py.template

# ln -s  $(pwd)/../mtproxy.service /etc/systemd/system/

curl -L -o install_mtproxy.sh https://gist.githubusercontent.com/hiddify/9134259f2df9ff91bb365c629512b6b3/raw/ec42ccfd96431686425a8f4e4e16a07d12062e82/install_mtproxy.sh
bash install_mtproxy.sh -p 1001 -s 00000000000000000000000000000001  -t 00000000000000000000000000000002 -a tls -d $TELEGRAM_FAKE_TLS_DOMAIN


cp prod-sys.config-base mtproto_proxy/config/prod-sys.config.template


# IP=$(curl -Lso- https://api.ipify.org);

# echo "https://t.me/proxy?server=$IP&port=443&secret=ee$16d61696c2e676f6f676c652e636f6d">use-link
