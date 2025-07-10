# mv /usr/local/etc/xray/config.json /usr/local/etc/xray/config.json.old
# ln -sf $(pwd)/xtls-config.json /usr/local/etc/xray/config.json
# ln -sf $(pwd)/xtls-sni-config.json /usr/local/etc/xray/config.json
#sed -i "s/^User=/#User=/g" /etc/systemd/system/xray.service
chmod -R 600 configs
mkdir -p run
ln -sf $(pwd)/hiddify-xray.service /etc/systemd/system/hiddify-xray.service
systemctl enable hiddify-xray.service

source /opt/hiddify-manager/common/utils.sh
activate_python_venv

# Fix the issue in xray that it can not read multiple inbound from single file
# python <<EOF
# import json,os
# for cfg in os.listdir('configs'):
# 	if cfg.endswith('.json') and 'reality' in cfg:
# 		with open(f'configs/{cfg}') as f:
# 			data=json.load(f)
# 		os.remove(f'configs/{cfg}')
# 		for i,inb in enumerate(data.get('inbounds',[])):
# 			new_data={'inbounds':[inb]}
# 			with open(f'configs/{i}_{cfg}','w') as f:
# 				json.dump(new_data,f,indent=4)
# EOF

# curl -s -x socks://127.0.0.1:3000 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query

if [ "$MODE" != "apply_users" ]; then
    
    # xray run -test -confdir configs
    echo "Ignoring xray test"
    if [[ $? == 0 ]]; then
        systemctl restart hiddify-xray.service
        systemctl start hiddify-xray.service
        #systemctl status hiddify-xray.service --no-pager
    else
        echo "Error in Xray Config!!!! do not reload xray service"
        sleep 60
        xray run -test -confdir configs
        if [[ $? == 0 ]]; then
            systemctl restart hiddify-xray.service
            systemctl start hiddify-xray.service
            #systemctl status hiddify-xray.service --no-pager
        else
            echo "Error in Xray Config!!!! do not reload xray service"
            sleep 60
        fi
    fi
    
fi
