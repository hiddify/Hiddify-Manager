echo "telegram proxy install.sh $*"

apt install -y python3 python3-uvloop python3-cryptography python3-socks libcap2-bin
useradd --no-create-home -s /usr/sbin/nologin tgproxy

git clone https://github.com/alexbers/mtprotoproxy 
cd  mtprotoproxy
sed "s/00000000000000000000000000000001/defaultusersecret/g" config.py > config.py.template
echo 'AD_TAG="telegramadtag"'>>config.py.template
echo 'TLS_DOMAIN = "telegramtlsdomain"'>> config.py.template
sed -i 's/PORT = 443/PORT = 449/g' config.py.template

ln -s  $(pwd)/../mtproxy.service /etc/systemd/system/



# IP=$(curl -Lso- https://api.ipify.org);

# echo "https://t.me/proxy?server=$IP&port=443&secret=ee$16d61696c2e676f6f676c652e636f6d">use-link
