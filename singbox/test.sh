
for CONFIG_FILE in $(find configs/ -name "*.json"); do
    sed -i 's|"proxy_protocol":true|"proxy_protocol":false|g' $CONFIG_FILE
done

systemctl restart hiddify-singbox
for CONFIG_FILE in $(find tests/ -name "*.json"); do
    echo "Running test on $CONFIG_FILE"
    sing-box run -c $CONFIG_FILE &
    pid=$!
    sleep 3
    curl -x socks://127.0.0.1:10000 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query
    if [ $? != 0 ];then
        exit 1
    fi
done

for CONFIG_FILE in $(find configs/ -name "*.json"); do
    sed -i 's|"proxy_protocol":false|"proxy_protocol":true|g' $CONFIG_FILE
done
systemctl restart hiddify-singbox