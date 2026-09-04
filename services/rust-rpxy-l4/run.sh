mkdir -p bin run log
ln -sf "$(pwd)/hiddify-rpxy-l4.service" /etc/systemd/system/hiddify-rpxy-l4.service
ln -sf "$(pwd)/hiddify-rpxy-l4-http.service" /etc/systemd/system/hiddify-rpxy-l4-http.service
systemctl daemon-reload
systemctl enable hiddify-rpxy-l4.service hiddify-rpxy-l4-http.service
systemctl restart hiddify-rpxy-l4.service hiddify-rpxy-l4-http.service
