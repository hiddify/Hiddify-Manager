systemctl kill mtproxy.service

if [ -f mtg/mtg ];then
    bash install.sh
fi

ln -sf  $(pwd)/mtproxy.service /etc/systemd/system/mtproxy.service
systemctl enable mtproxy.service
systemctl restart mtproxy.service

