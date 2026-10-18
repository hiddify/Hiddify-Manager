source /opt/hiddify-manager/scripts/common/utils.sh

install_package shadowsocks-libev simple-obfs
# Templates may not be rendered yet on a fresh tree; ignore missing globs.
chmod 600 *.service* >/dev/null 2>&1 || true
if [ -f hiddify-ss-faketls.service ]; then
  ln -sf "$(pwd)/hiddify-ss-faketls.service" /etc/systemd/system/hiddify-ss-faketls.service
fi
# Old package unit (may not exist) — never fail the step.
systemctl disable --now ss-faketls.service >/dev/null 2>&1 || true
rm -f ss-faketls.service ss-faketls.service.* >/dev/null 2>&1 || true
