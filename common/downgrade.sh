cd /opt/hiddify-server/hiddify-panel
python3 -m hiddifypanel downgrade
cd ..
pip install hiddifypanel==7.2.0
curl -L -o hiddify-server.zip https://github.com/hiddify/hiddify-server/releases/download/v10.1.3/hiddify-server.zip
unzip -o hiddify-server.zip
rm hiddify-server.zip
bash install.sh
