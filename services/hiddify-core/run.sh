source /opt/hiddify-manager/scripts/common/utils.sh
ln -sf $(pwd)/hiddify-core.service /etc/systemd/system/hiddify-core.service
systemctl daemon-reload
systemctl enable hiddify-core.service
# Drop the old unit name if it is still installed
if [ -e /etc/systemd/system/hiddify-singbox.service ]; then
	systemctl disable --now hiddify-singbox.service 2>/dev/null || true
	rm -f /etc/systemd/system/hiddify-singbox.service
	systemctl daemon-reload
fi

set_files_in_folder_readable_to_hiddify_common_group /opt/hiddify-manager/generated/hiddify-core.json

# curl -s -x socks://127.0.0.1:3000 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query

# hiddify-core check -c /opt/hiddify-manager/generated/hiddify-core.json
echo "ignoring hiddify-core test"
if [[ $? == 0 ]]; then
	#systemctl restart hiddify-core.service
	systemctl reload hiddify-core.service
	systemctl start hiddify-core.service
	# systemctl status hiddify-core.service --no-pager
else
	echo "Error in hiddify-core Config!!!! do not reload hiddify-core service"
	sleep 3
	hiddify-core check -c /opt/hiddify-manager/generated/hiddify-core.json
	if [[ $? == 0 ]]; then
		systemctl reload hiddify-core.service
		systemctl start hiddify-core.service
		systemctl status hiddify-core.service --no-pager
	else
		echo "Error in hiddify-core Config!!!! do not reload hiddify-core service"
	fi
fi
