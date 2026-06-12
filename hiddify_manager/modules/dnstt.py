import os

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import module_dir as _module_dir
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.package_manager import download_package


def install():
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
