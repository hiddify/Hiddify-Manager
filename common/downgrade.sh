cd /opt/hiddify-server/hiddify-panel
python3 -m hiddifypanel downgrade
if [ ! -f hiddifypanel.db ] && [ -f hiddifypanel.db.old ]; then
    mv hiddifypanel.db.old hiddifypanel.db
fi
cd ..

source common/utils.sh

pip install hiddifypanel==$(get_release_version hiddifypanel)
curl -L -o hiddify-server.zip https://github.com/hiddify/hiddify-server/releases/latest/download/hiddify-server.zip
unzip -o hiddify-server.zip
rm hiddify-server.zip
bash install.sh
