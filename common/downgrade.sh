cd /opt/hiddify-config/
pip install hiddifypanel==7.2.0
curl -L -o hiddify-config.zip   https://github.com/hiddify/hiddify-config/releases/download/v10.1.3/hiddify-config.zip  
unzip -o hiddify-config.zip
rm hiddify-config.zip
bash install.sh