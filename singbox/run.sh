source /opt/hiddify-manager/common/utils.sh
ln -sf $(pwd)/hiddify-singbox.service /etc/systemd/system/hiddify-singbox.service
systemctl enable hiddify-singbox.service

set_files_in_folder_readable_to_hiddify_common_group configs/01_api.json

# curl -s -x socks://127.0.0.1:3000 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query

# sing-box check -C configs
echo "ignoring singbox test"
if [[ $? == 0 ]]; then
	#systemctl restart hiddify-singbox.service
	systemctl reload hiddify-singbox.service
	systemctl start hiddify-singbox.service
	# systemctl status hiddify-singbox.service --no-pager
else
	echo "Error in singbox Config!!!! do not reload singbox service"
	sleep 3
	singbox check -C configs
	if [[ $? == 0 ]]; then
		systemctl reload hiddify-singbox.service
		systemctl start hiddify-singbox.service
		systemctl status hiddify-singbox.service --no-pager
	else
		echo "Error in singbox Config!!!! do not reload singbox service"
	fi
fi
