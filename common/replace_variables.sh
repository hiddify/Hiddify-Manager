
rm /opt/hiddify-manager/xray/configs/*.json
rm /opt/hiddify-manager/singbox/configs/*.json
rm /opt/hiddify-manager/haproxy/*.cfg
python -c "import json5;import jinja2" || pip install json5 jinja2
python3 /opt/hiddify-manager/common/jinja.py
