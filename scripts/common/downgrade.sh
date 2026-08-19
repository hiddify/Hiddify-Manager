cd /opt/hiddify-manager/services/hiddify-panel

source /opt/hiddify-manager/scripts/common/utils.sh
activate_python_venv

hiddify-panel-cli downgrade
if [ ! -f hiddifypanel.db ] && [ -f hiddifypanel.db.old ]; then
    mv hiddifypanel.db.old hiddifypanel.db
fi
cd /opt/hiddify-manager


pip install hiddifypanel==$(get_release_version hiddify-panel)
curl -L -s -o hiddify-manager.zip https://github.com/hiddify/hiddify-manager/releases/latest/download/hiddify-manager.zip
unzip -o hiddify-manager.zip
rm hiddify-manager.zip
ln -s /opt/hiddify-manager /opt/hiddify-config
bash scripts/install.sh
