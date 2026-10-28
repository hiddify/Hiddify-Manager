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

mkdir -p /opt/hiddify-manager/data/hiddify-core
set_files_in_folder_readable_to_hiddify_common_group /opt/hiddify-manager/generated/hiddify-core.json

# curl -s -x socks://127.0.0.1:3000 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query

# hiddify-core check -c /opt/hiddify-manager/generated/hiddify-core.json
rm /opt/hiddify-manager/data/hiddify-core/tor/lock 2>/dev/null || true
# A reload keeps the running binary: after install.sh put a new one in place, restart onto it.
main_pid=$(systemctl show -p MainPID --value hiddify-core.service 2>/dev/null)
if [[ "$main_pid" != "" && "$main_pid" != "0" && "$(readlink /proc/$main_pid/exe 2>/dev/null)" == *" (deleted)" ]]; then
	systemctl restart hiddify-core.service
fi
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
