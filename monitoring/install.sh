apt install -y python3-pip cron
pip install -U git+https://github.com/hiddify/hiddify-monitoring
pip install bottle pandas numpy

systemctl kill hiddify_monitoring_web.service