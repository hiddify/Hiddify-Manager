systemctl enable netdata
rm /usr/share/netdata/web/dash.html
cp $(pwd)/dash.html /usr/share/netdata/web/dash.html
systemctl restart netdata