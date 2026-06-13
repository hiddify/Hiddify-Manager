import json
import os
import tarfile
import urllib.request
from urllib.parse import urlparse

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import module_dir as _module_dir
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.package_manager import get_arch
from hiddify_manager.utils.config import hiddify_config


def _latest_release(repo):
    url = f"https://api.github.com/repos/hiddify/{repo}/releases"
    try:
        with urllib.request.urlopen(url, timeout=10) as r:
            data = json.load(r)
        non_pre = [x for x in data if not x.get("prerelease")]
        non_pre.sort(key=lambda x: x.get("created_at", ""))
        if non_pre:
            return non_pre[-1]["tag_name"].lstrip("v")
    except Exception as e:
        log.warning(f"github api lookup failed for {repo}: {e}")
    return None


def _download_and_extract(module_dir, version):
    arch = get_arch()
    url = (
        f"https://github.com/hiddify/hiddify-core/releases/download/"
        f"v{version}/hiddify-core-linux-{arch}.tar.gz"
    )
    tarball = os.path.join(module_dir, "hiddify-core.tar.gz")
    log.info(f"downloading HiddifyCli {version} for {arch}")
    urllib.request.urlretrieve(url, tarball)
    with tarfile.open(tarball, "r:gz") as t:
        t.extractall(module_dir)
    os.remove(tarball)
    for entry in os.listdir(module_dir):
        sub = os.path.join(module_dir, entry)
        if entry.startswith("hiddify-core-") and os.path.isdir(sub):
            for name in os.listdir(sub):
                os.rename(os.path.join(sub, name), os.path.join(module_dir, name))
            os.rmdir(sub)
    with open(os.path.join(module_dir, "VERSION"), "w") as f:
        f.write(version)


def _write_env(module_dir, configs):
    if not configs:
        log.warning("no panel configs available — skipping hiddify-cli .env")
        return
    hconfigs = configs.get("hconfigs", {})
    chconfigs = configs.get("chconfigs", {})
    if not hconfigs and isinstance(chconfigs, dict):
        try:
            hconfigs = chconfigs.get(0) or chconfigs.get("0", {})
        except AttributeError:
            hconfigs = {}

    # Legacy run.sh.j2 computes a public PANEL_DOMAIN from panel_links then
    # immediately overrides it to http://127.0.0.1:9000, so the public value
    # is dead code. We use localhost directly — that way hiddify-cli works
    # before nginx/haproxy bind 443, and won't get stranded on a public DNS
    # name pointing somewhere else.
    panel_domain = "http://127.0.0.1:9000"
    _ = configs.get("panel_links")  # kept for parity with the legacy template

    proxy_path = hconfigs.get("proxy_path_client", "")
    users = configs.get("users") or []
    uuid = users[0]["uuid"] if users else ""
    sub_link = f"{panel_domain}/{proxy_path}/{uuid}/singbox/"

    env_file = os.path.join(module_dir, ".env")
    with open(env_file, "w") as f:
        f.write(f"SUB_LINK={sub_link}\n")
    run_cmd(["chown", "hiddify-cli", env_file], check=False)
    os.chmod(env_file, 0o600)


UNIT = "hiddify-cli.service"


def _disable():
    run_cmd(["systemctl", "stop", UNIT], check=False)
    run_cmd(["systemctl", "disable", UNIT], check=False)


def install():
    configs = hiddify_config() or {}
    hconfigs = configs.get("hconfigs") or {}
    if not hconfigs.get("hiddifycli_enable"):
        log.info("hiddify-cli: hiddifycli_enable is false — stopping unit and skipping install")
        _disable()
        return

    module_dir = _module_dir("other/hiddify-cli")
    run_cmd(["useradd", "-m", "hiddify-cli", "-s", "/bin/bash"], check=False)

    bin_path = os.path.join(module_dir, "HiddifyCli")
    version_file = os.path.join(module_dir, "VERSION")
    have_version = ""
    if os.path.exists(version_file):
        have_version = open(version_file).read().strip()

    latest = _latest_release("hiddify-core")
    if latest and (have_version != latest or not os.path.exists(bin_path)):
        _download_and_extract(module_dir, latest)
    else:
        log.info("HiddifyCli already up to date" if latest else "skipping HiddifyCli download (no version)")

    svc = os.path.join(module_dir, "hiddify-cli.service")
    if os.path.exists(svc):
        run_cmd(["ln", "-sf", svc, "/etc/systemd/system/hiddify-cli.service"])
    run_cmd(["systemctl", "enable", "hiddify-cli.service"], check=False)

    _write_env(module_dir, configs)
    run_cmd(["chown", "-R", "hiddify-cli", module_dir], check=False)
    run_cmd(["systemctl", "restart", "hiddify-cli.service"], check=False)
