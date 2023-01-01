systemctl kill hiddify_monitoring_web.service
systemctl disable hiddify_monitoring_web.service
rm /etc/cron.d/hiddify-monitoring
service cron reload