cd /opt/hiddify-config/hiddify-panel
python3 -m hiddifypanel downgrade
cd ..

source common/utils.sh

pip install hiddifypanel==$(get_release_version hiddifypanel)
curl -L -o hiddify-config.zip https://github.com/hiddify/hiddify-config/releases/latest/download/hiddify-config.zip
unzip -o hiddify-config.zip
rm hiddify-config.zip
bash install.sh
