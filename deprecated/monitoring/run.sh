
systemctl kill hiddify_monitoring_web.service
mkdir -p ../log/stats/
ln -sf $(pwd)/hiddify_monitoring_web.service /etc/systemd/system/hiddify_monitoring_web.service
echo "0,15,30,45 * * * * root $(pwd)/cron.sh" > /etc/cron.d/hiddify-monitoring
service cron reload
systemctl enable hiddify_monitoring_web.service
systemctl restart hiddify_monitoring_web.service
