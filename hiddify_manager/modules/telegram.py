import os

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import module_dir as _module_dir
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.config import hiddify_config
from hiddify_manager.utils.template import render_template


def _disable_legacy():
    for unit in ("mtproxy", "mtproto-proxy"):
        run_cmd(["systemctl", "stop", unit], check=False)
        run_cmd(["systemctl", "disable", unit], check=False)


def install():
    """
    Replaces other/telegram/install.sh.j2 + run.sh.j2.

    The original templates dispatch to a subdir named by
    hconfigs['telegram_lib'] (e.g. 'python' or 'tgo'); each subdir
    has its own install.sh + run.sh that handle the actual setup.
    """
    base = _module_dir("other/telegram")
    _disable_legacy()

    configs = hiddify_config()
    if not configs:
        log.warning("telegram: no panel configs available — skipping")
        return

    hconfigs = configs.get("hconfigs") or {}
    telegram_lib = hconfigs.get("telegram_lib")
    if not telegram_lib:
        log.info("telegram: telegram_lib not set in hconfigs — nothing to do")
        return

    lib_dir = os.path.join(base, telegram_lib)
    if not os.path.isdir(lib_dir):
        log.warning(f"telegram: lib dir {lib_dir} does not exist")
        return

    # Render any *.j2 inside the lib dir against current configs.
    for name in os.listdir(lib_dir):
        if name.endswith(".j2"):
            render_template(os.path.join(lib_dir, name), configs)

    install_sh = os.path.join(lib_dir, "install.sh")
    run_sh = os.path.join(lib_dir, "run.sh")
    if os.path.exists(install_sh):
        run_cmd(["bash", "install.sh"], cwd=lib_dir, check=False)
    if os.path.exists(run_sh):
        run_cmd(["bash", "run.sh"], cwd=lib_dir, check=False)
