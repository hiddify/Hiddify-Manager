import glob
import os

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import module_dir as _module_dir
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.config import hiddify_config
from hiddify_manager.utils.template import render_template


def install():
    module_dir = _module_dir("other/ssfaketls")
    run_cmd(["apt-get", "install", "-y", "shadowsocks-libev", "simple-obfs"])

    for svc in glob.glob(os.path.join(module_dir, "*.service*")):
        os.chmod(svc, 0o600)

    tpl = os.path.join(module_dir, "hiddify-ss-faketls.service.j2")
    if os.path.exists(tpl):
        configs = hiddify_config()
        if not configs:
            log.error("ssfaketls: no panel configs available — cannot render service")
            return
        rendered = render_template(tpl, configs)
        if not rendered:
            return

    svc_path = os.path.join(module_dir, "hiddify-ss-faketls.service")
    if os.path.exists(svc_path):
        run_cmd(["ln", "-sf", svc_path, "/etc/systemd/system/hiddify-ss-faketls.service"])

    # Migrate away from legacy ss-faketls.service that used to ship here.
    run_cmd(["systemctl", "disable", "--now", "ss-faketls.service"], check=False)
    for stale in glob.glob(os.path.join(module_dir, "ss-faketls.service*")):
        try:
            os.remove(stale)
        except OSError:
            pass

    run_cmd(["systemctl", "enable", "hiddify-ss-faketls.service"], check=False)
    run_cmd(["systemctl", "restart", "hiddify-ss-faketls.service"], check=False)
