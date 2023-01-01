
ln -s $(pwd)/hiddify-admin.service /etc/systemd/system/hiddify-admin.service
systemctl enable hiddify-admin.service
systemctl restart hiddify-admin.service
