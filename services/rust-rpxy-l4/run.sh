mkdir -p bin run log
ln -sf "$(pwd)/hiddify-rpxy-l4.service" /etc/systemd/system/hiddify-rpxy-l4.service
systemctl daemon-reload
# Always enabled. Only start it if it is not running: rpxy-l4 picks up changes to
# generated/rust-rpxy-l4.toml on the fly, so a restart would only drop connections.
systemctl enable --now hiddify-rpxy-l4.service
