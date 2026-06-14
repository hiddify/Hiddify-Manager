"""
Telegram MTProto proxy.

Two backends, selected by hconfigs['telegram_lib']:

  - 'python' : github.com/hiddify/mtprotoproxy (pure-python, asyncio-based)
  - 'tgo'    : github.com/9seconds/mtg (Go binary distributed as a tarball)

Each gets its config rendered from a .j2 template, then we link the
shared mtproxy.service systemd unit and restart it.
"""
import glob
import os
import shutil
import tarfile

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import module_dir as _module_dir
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.config import hiddify_config
from hiddify_manager.utils.template import render_template
from hiddify_manager.utils.package_manager import download_package


def _disable_legacy():
    """Stop any pre-existing mtproxy/mtproto-proxy units before reinstalling."""
    for unit in ("mtproxy", "mtproto-proxy"):
        run_cmd(["systemctl", "stop", unit], check=False)
        run_cmd(["systemctl", "disable", unit], check=False)


def _wire_service(lib_dir, secret_glob):
    """
    Common tail for both backends: link the shared mtproxy.service unit,
    chmod the rendered config to 0600 (no world-readable secrets), enable
    and restart the unit.

    secret_glob picks which files in lib_dir to chmod (.py for python,
    .toml for tgo). Includes the .j2 source too — harmless, and matches
    the legacy `chmod 600 *.py*` / `chmod 600 *toml*` patterns.
    """
    svc = os.path.join(lib_dir, "mtproxy.service")
    if os.path.exists(svc):
        run_cmd(["ln", "-sf", svc, "/etc/systemd/system/mtproxy.service"], check=False)
        run_cmd(["systemctl", "enable", "mtproxy.service"], check=False)

    for path in glob.glob(os.path.join(lib_dir, secret_glob)):
        try:
            os.chmod(path, 0o600)
        except OSError as e:
            log.warning(f"telegram: chmod 600 failed for {path}: {e}")

    run_cmd(["systemctl", "restart", "mtproxy.service"], check=False)


def _install_python_backend(lib_dir, configs):
    """Replaces other/telegram/python/{install.sh,run.sh}."""
    run_cmd(
        ["apt-get", "install", "-y",
         "python3", "python3-uvloop", "python3-cryptography",
         "python3-socks", "libcap2-bin"],
        check=False,
    )
    run_cmd(
        ["useradd", "--no-create-home", "-s", "/usr/sbin/nologin", "tgproxy"],
        check=False,
    )

    clone_dir = os.path.join(lib_dir, "mtprotoproxy")
    if not os.path.isdir(clone_dir):
        run_cmd(
            ["git", "clone", "https://github.com/hiddify/mtprotoproxy", clone_dir],
            check=False,
        )

    # Render config.py.j2 -> config.py, then mirror it into the clone.
    tpl = os.path.join(lib_dir, "config.py.j2")
    if os.path.exists(tpl):
        render_template(tpl, configs)
    rendered = os.path.join(lib_dir, "config.py")
    if os.path.exists(rendered) and os.path.isdir(clone_dir):
        shutil.copy(rendered, os.path.join(clone_dir, "config.py"))

    _wire_service(lib_dir, "*.py*")


def _install_tgo_backend(lib_dir, configs):
    """Replaces other/telegram/tgo/{install.sh,run.sh}."""
    tarball = os.path.join(lib_dir, "mtg-linux.tar.gz")
    if not download_package("mtproxygo", tarball):
        log.error("telegram: failed to download mtproxygo")
        return

    try:
        with tarfile.open(tarball, "r:gz") as t:
            t.extractall(lib_dir)
    except (tarfile.TarError, OSError) as e:
        log.error(f"telegram: extracting mtg tarball failed: {e}")
        return
    finally:
        try:
            os.remove(tarball)
        except OSError:
            pass

    # The tarball contains a single mtg-* directory holding the binary;
    # promote it to lib_dir/mtg and remove the subdir.
    for entry in os.listdir(lib_dir):
        sub = os.path.join(lib_dir, entry)
        if entry.startswith("mtg-") and os.path.isdir(sub):
            bin_src = os.path.join(sub, "mtg")
            bin_dst = os.path.join(lib_dir, "mtg")
            if os.path.exists(bin_src):
                os.replace(bin_src, bin_dst)
                os.chmod(bin_dst, 0o755)
            shutil.rmtree(sub, ignore_errors=True)
            break

    tpl = os.path.join(lib_dir, "mtg.toml.j2")
    if os.path.exists(tpl):
        render_template(tpl, configs)

    _wire_service(lib_dir, "*toml*")


_BACKENDS = {
    "python": _install_python_backend,
    "tgo": _install_tgo_backend,
}


def install():
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

    handler = _BACKENDS.get(telegram_lib)
    if handler is None:
        log.warning(f"telegram: unknown backend {telegram_lib!r}")
        return

    lib_dir = os.path.join(_module_dir("other/telegram"), telegram_lib)
    if not os.path.isdir(lib_dir):
        log.warning(f"telegram: lib dir {lib_dir} does not exist")
        return

    log.info(f"telegram: installing {telegram_lib} backend")
    handler(lib_dir, configs)
