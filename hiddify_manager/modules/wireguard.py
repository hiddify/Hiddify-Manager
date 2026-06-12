import os

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import module_dir as _module_dir
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.config import hiddify_config
from hiddify_manager.utils.template import render_template


def install():
    module_dir = _module_dir("other/wireguard")
    configs = hiddify_config()
    if not configs:
        log.error("wireguard: no panel configs available — aborting")
        return

    for fname in ("install.sh.j2", "run.sh.j2"):
        tpl = os.path.join(module_dir, fname)
        if not os.path.exists(tpl):
            continue
        if not render_template(tpl, configs):
            log.error(f"wireguard: failed to render {fname}")
            return

    install_sh = os.path.join(module_dir, "install.sh")
    run_sh = os.path.join(module_dir, "run.sh")
    if os.path.exists(install_sh):
        run_cmd(["bash", "install.sh"], cwd=module_dir, check=False)
    if os.path.exists(run_sh):
        run_cmd(["bash", "run.sh"], cwd=module_dir, check=False)
