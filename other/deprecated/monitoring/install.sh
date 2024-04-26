source /opt/hiddify-manager/common/utils.sh
activate_python_venv
apt install -y cron
pip install -U git+https://github.com/hiddify/hiddify-monitoring
pip install bottle pandas numpy

systemctl kill hiddify_monitoring_web.service