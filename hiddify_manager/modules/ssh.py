import os
import re

from hiddify_manager.utils.config import hiddify_config
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import module_dir as _module_dir
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.package_manager import download_package


UNIT = "hiddify-ssh-liberty-bridge.service"


def _disable():
    run_cmd(["systemctl", "stop", UNIT], check=False)
    run_cmd(["systemctl", "disable", UNIT], check=False)


def _redis_password():
    redis_conf = os.path.join(_module_dir("other/redis"), "redis.conf")
    if not os.path.exists(redis_conf):
        return None
    with open(redis_conf) as f:
        for line in f:
            if line.strip().startswith("requirepass"):
                parts = line.split()
                if len(parts) >= 2:
                    return parts[1]
    return None


def install():
    """
    ssh-liberty-bridge is the panel's SSH-as-proxy backend. The legacy
    install.sh ran `install_run other/ssh 0` — hardcoded false — so this
    was never installed by default. We gate on hconfigs['ssh_server_enable']
    so an operator who DOES want it gets it, and the default install
    (matching legacy behaviour) stops the unit.

    Without this gate ssh-liberty-bridge would race singbox's `inbound/ssh`
    for the same TCP port and one or the other crashloops.
    """
    configs = hiddify_config() or {}
    hconfigs = configs.get("hconfigs") or {}
    if not hconfigs.get("ssh_server_enable"):
        log.info("ssh: ssh_server_enable is false — stopping unit and skipping install")
        _disable()
        return

    module_dir = _module_dir("other/ssh")
    os.makedirs(os.path.join(module_dir, "host_key"), exist_ok=True)

    bin_path = os.path.join(module_dir, "ssh-liberty-bridge")
    if download_package("ssh-liberty-bridge", bin_path):
        os.chmod(bin_path, 0o755)
        run_cmd(["useradd", "liberty-bridge"], check=False)

    for env in ("env", "env.local"):
        p = os.path.join(module_dir, f".{env}")
        if os.path.exists(p):
            run_cmd(["chown", "liberty-bridge", p], check=False)

    svc = os.path.join(module_dir, "hiddify-ssh-liberty-bridge.service")
    if os.path.exists(svc):
        run_cmd(["ln", "-sf", svc, "/etc/systemd/system/hiddify-ssh-liberty-bridge.service"])

    run_cmd(["chown", "-R", "liberty-bridge", os.path.join(module_dir, "host_key")], check=False)

    env_file = os.path.join(module_dir, ".env")
    lines = []
    if os.path.exists(env_file):
        with open(env_file) as f:
            lines = [ln for ln in f if not ln.startswith("REDIS_URL")]

    redis_uri = os.environ.get("REDIS_URI_SSH")
    if not redis_uri:
        pw = _redis_password()
        if pw:
            redis_uri = f"redis://:{pw}@127.0.0.1:6379/1"

    if redis_uri:
        lines.append(f"REDIS_URL='{redis_uri}'\n")

    with open(env_file, "w") as f:
        f.writelines(lines)
    os.chmod(env_file, 0o600)

    run_cmd(["systemctl", "enable", "hiddify-ssh-liberty-bridge"], check=False)
    run_cmd(["systemctl", "restart", "hiddify-ssh-liberty-bridge"], check=False)
