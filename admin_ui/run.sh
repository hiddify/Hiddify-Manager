
ln -s $(pwd)/hiddify-admin.service /etc/systemd/system/hiddify-admin.service
systemctl enable hiddify-admin.service
systemctl start hiddify-admin.service
