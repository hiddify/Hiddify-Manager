chmod 600 config.toml* 2>/dev/null || true
mkdir -p bin run log
ln -sf "$(pwd)/hiddify-rpxy-l4.service" /etc/systemd/system/hiddify-rpxy-l4.service
systemctl daemon-reload
systemctl enable hiddify-rpxy-l4.service
systemctl restart hiddify-rpxy-l4.service
