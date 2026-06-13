import os

from hiddify_manager.utils.config import hiddify_config
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import module_dir as _module_dir
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.package_manager import download_package


UNIT = "hiddify-dnstm-router.service"


def _disable():
    """Stop the unit if it's running. Idempotent — fine if the unit was never installed."""
    run_cmd(["systemctl", "stop", UNIT], check=False)
    run_cmd(["systemctl", "disable", UNIT], check=False)


def install():
    """
    Set up the dnstt DNS-tunnel server *if* the panel has dnstt_enable set.
    Legacy install_run other/dnstt $(hconfig "dnstt_enable") gated the
    whole install on that flag; without the gate we end up crash-looping
    the service on dev boxes where dnstt_enable is false (UDP/53 is bound
    by systemd-resolved or the real DNS resolver).
    """
    configs = hiddify_config() or {}
    hconfigs = configs.get("hconfigs") or {}
    if not hconfigs.get("dnstt_enable"):
        log.info("dnstt: dnstt_enable is false — stopping unit and skipping install")
        _disable()
        return

    module_dir = _module_dir("other/dnstt")
    os.makedirs(module_dir, exist_ok=True)

    dnstm = os.path.join(module_dir, "dnstm")
    if download_package("dnstm", dnstm):
        os.chmod(dnstm, 0o755)

    server_bin = os.path.join(module_dir, "dnstt-server")
    if download_package("vaydns", server_bin):
        os.chmod(server_bin, 0o755)

        priv = os.path.join(module_dir, "server.key")
        pub = os.path.join(module_dir, "server.pub")
        if not os.path.exists(pub):
            log.info("generating dnstt server keypair")
            run_cmd(
                [server_bin, "-gen-key", "-privkey-file", priv, "-pubkey-file", pub],
                cwd=module_dir,
                check=False,
            )

        run_cmd(["useradd", "dnstt"], check=False)
        for p in (priv, pub):
            if os.path.exists(p):
                run_cmd(["chown", "dnstt:dnstt", p], check=False)
        if os.path.exists(priv):
            os.chmod(priv, 0o600)
        if os.path.exists(pub):
            os.chmod(pub, 0o644)
