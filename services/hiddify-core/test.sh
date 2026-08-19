CONFIG_FILE=/opt/hiddify-manager/generated/hiddify-core.json
sed -i 's|"proxy_protocol":true|"proxy_protocol":false|g' "$CONFIG_FILE"

systemctl restart hiddify-core
for TEST_FILE in $(find tests/ -name "*.json"); do
    echo ""
    echo ""
    echo "==================================="
    echo "Running test on $TEST_FILE"
    ./hiddify-core run -c $TEST_FILE &
    pid=$!
    sleep 3
    curl -x socks://127.0.0.1:10000 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query
    if [ $? != 0 ];then
        echo "ERROR: $TEST_FILE "
        kill -9 $pid
        exit 1
    else
        echo "SUCCESS: $TEST_FILE "
    fi
    kill -9 $pid
done

sed -i 's|"proxy_protocol":false|"proxy_protocol":true|g' "$CONFIG_FILE"
systemctl restart hiddify-core
