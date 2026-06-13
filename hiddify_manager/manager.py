import argparse
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.system import check_root
from hiddify_manager.installer import install_module


def _render_all_templates():
    """
    After the panel is up, walk the project tree and render every *.j2
    file against current.json, then ensure each domain has a self-signed
    cert under ssl/ (haproxy and nginx both refuse to start otherwise).
    Mirrors what common/jinja.py + replace_variables.sh did in the
    legacy install chain.
    """
    import os
    from hiddify_manager.utils.config import hiddify_config
    from hiddify_manager.utils.template import render_tree
    from hiddify_manager.utils.shell import run_cmd
    from hiddify_manager.utils.paths import PROJECT_ROOT

    configs = hiddify_config()
    if not configs:
        log.warning("render_all: no panel configs available — skipping global render")
        return
    log.info("Rendering all *.j2 templates against current.json...")
    render_tree([PROJECT_ROOT], configs)

    # Generate self-signed certs for every domain so haproxy/nginx can start.
    # Real certs are fetched later by acme.sh if/when DNS points here.
    cert_script = os.path.join(PROJECT_ROOT, "acme.sh", "generate_self_signed_cert.sh")
    if os.path.exists(cert_script):
        for d in (configs.get("domains") or []):
            domain = d.get("domain") if isinstance(d, dict) else None
            if domain:
                run_cmd(
                    ["bash", cert_script, domain],
                    cwd=os.path.dirname(cert_script),
                    check=False,
                    capture_output=True,
                )


def run_install():
    log.info("Starting installation...")
    modules = [
        "common", "other/redis", "other/mysql", "hiddify-panel",
        "nginx", "haproxy", "acme.sh", "other/speedtest", "other/dnstt",
        "other/telegram", "other/ssfaketls", "other/ssh", "other/warp",
        "xray", "other/hiddify-cli", "other/wireguard", "singbox"
    ]
    for mod in modules:
        install_module(mod)
        if mod == "hiddify-panel":
            _render_all_templates()
    log.info("Installation completed successfully.")

def main():
    parser = argparse.ArgumentParser(description="Hiddify-Manager Configuration Tool")
    parser.add_argument("command", nargs="?", choices=["install", "update", "status", "menu", "migrate"], help="Command to run")
    
    args = parser.parse_args()
    
    check_root()
    
    if not args.command or args.command == "menu":
        from hiddify_manager.menu import show_menu
        show_menu()
    elif args.command == "install":
        run_install()
    elif args.command == "update":
        log.info("Starting update...")
        from hiddify_manager.utils.shell import run_cmd
        run_cmd(["bash", "update.sh"])
    elif args.command == "status":
        log.info("Checking status...")
        from hiddify_manager.utils.shell import run_cmd
        run_cmd(["bash", "status.sh"])
    elif args.command == "migrate":
        from hiddify_manager.migrate import run_migration
        run_migration()

if __name__ == "__main__":
    main()
