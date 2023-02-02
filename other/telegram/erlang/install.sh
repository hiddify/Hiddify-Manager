echo "telegram proxy install.sh $*"
systemctl stop mtproxy.service
systemctl disable mtproxy.service

# apt install -y python3 python3-uvloop python3-cryptography python3-socks libcap2-bin
# useradd --no-create-home -s /usr/sbin/nologin tgproxy

# git clone https://github.com/alexbers/mtprotoproxy 
# cd  mtprotoproxy
# sed "s/00000000000000000000000000000001/defaultusersecret/g" config.py > config.py.template
# echo 'AD_TAG="telegramadtag"'>>config.py.template
# echo 'TLS_DOMAIN = "telegramtlsdomain"'>> config.py.template
# sed -i 's/PORT = 443/PORT = 1001/g' config.py.template

# ln -s  $(pwd)/../mtproxy.service /etc/systemd/system/

curl -L -o install_mtproxy.sh https://gist.githubusercontent.com/hiddify/9134259f2df9ff91bb365c629512b6b3/raw/e2738060612914aa5c82268b084b89e81ceaada1/install_mtproxy.sh
bash install_mtproxy.sh -p 1001 -s 00000000000000000000000000000001  -t 00000000000000000000000000000002 -a tls -d google.com


cp prod-sys.config-base mtproto_proxy/config/prod-sys.config.template


# IP=$(curl -Lso- https://api.ipify.org);

# echo "https://t.me/proxy?server=$IP&port=443&secret=ee$16d61696c2e676f6f676c652e636f6d">use-link
