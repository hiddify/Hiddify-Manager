apt install -y python3 python3-uvloop python3-cryptography python3-socks libcap2-bin
useradd --no-create-home -s /usr/sbin/nologin tgproxy

ln -sf  $(pwd)/mtproxy.service /etc/systemd/system/

git clone https://github.com/alexbers/mtprotoproxy 
cd  mtprotoproxy
sed "s/00000000000000000000000000000001/defaultusersecret/g" config.py > config.py.template
echo 'AD_TAG="telegramadtag"'>>config.py.template
echo 'TLS_DOMAIN = "telegramtlsdomain"'>> config.py.template
sed -i 's/PORT = 443/PORT = 1001/g' config.py.template

