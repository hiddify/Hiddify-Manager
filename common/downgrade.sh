cd /opt/hiddify-config/hiddify-panel
python3 -m hiddifypanel downgrade
if [ ! -f hiddifypanel.db ] && [ -f hiddifypanel.db.old ]; then
    mv hiddifypanel.db.old hiddifypanel.db
fi
cd ..

source common/utils.sh

pip install hiddifypanel==$(get_release_version hiddifypanel)
curl -L -o hiddify-config.zip https://github.com/hiddify/hiddify-config/releases/latest/download/hiddify-config.zip
unzip -o hiddify-config.zip
rm hiddify-config.zip
bash install.sh
