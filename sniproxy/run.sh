# rm /etc/sniproxy.conf
# ln -sf $(pwd)/sniproxy.conf /etc/sniproxy.conf

if [ "$ENABLE_SHADOW_TLS" == "false" ];then
    sed -i "s|$SHADOWTLS_FAKEDOMAIN|#|g" sniproxy.conf
fi

if [ "$ENABLE_SSR" == "false" ];then
    sed -i "s|$SSR_FAKEDOMAIN|#|g" sniproxy.conf
fi

if [ "$ENABLE_SS" == "false" ];then
    sed -i "s|$SS_FAKE_TLS_DOMAIN|#|g" sniproxy.conf
fi

if [ "$ENABLE_TELEGRAM" == "false" ];then
    sed -i "s|$TELEGRAM_FAKE_TLS_DOMAIN|#|g" sniproxy.conf
fi


pkill -9 sniproxy
kill -9 `lsof -t -i:443`
kill -9 `lsof -t -i:80`
systemctl restart hiddify-sniproxy.service
systemctl status  hiddify-sniproxy.service