import os

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import module_dir as _module_dir
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.config import hiddify_config
from hiddify_manager.utils.template import render_template
from hiddify_manager.utils.package_manager import download_package


def install():
    """
    Install warp via the wgcf binary, then render and execute the warp
    run script (which registers/updates the wgcf account and brings up
    wg-quick@warp).
    """
    base = _module_dir("other/warp")
    wg_dir = os.path.join(base, "wireguard")
    os.makedirs(wg_dir, exist_ok=True)

    run_cmd(["apt-get", "install", "-y", "wireguard-tools"], check=False)

    wgcf_path = os.path.join(wg_dir, "wgcf")
    if download_package("wgcf", wgcf_path):
        os.chmod(wgcf_path, 0o755)

    configs = hiddify_config()
    if not configs:
        log.error("warp: no panel configs available — aborting render")
        return

    tpl = os.path.join(wg_dir, "run.sh.j2")
    if os.path.exists(tpl):
        if not render_template(tpl, configs):
            log.error("warp: failed to render run.sh.j2")
            return

    run_sh = os.path.join(wg_dir, "run.sh")
    if os.path.exists(run_sh):
        run_cmd(["bash", "run.sh"], cwd=wg_dir, check=False)
