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

    # Generate self-signed certs BEFORE the template render — some
    # templates (singbox/xray inbounds with TLS) shell to `ls ssl/*.crt`
    # via the exec() helper and bake the listing into their JSON. If we
    # render first, those captures contain the "ls: cannot access" error
    # string and the config consumer fails to parse it.
    from hiddify_manager.utils.certs import ensure_self_signed_cert
    ssl_dir = os.path.join(PROJECT_ROOT, "ssl")
    for d in (configs.get("domains") or []):
        domain = d.get("domain") if isinstance(d, dict) else None
        if domain:
            ensure_self_signed_cert(domain, ssl_dir)

    log.info("Rendering all *.j2 templates against current.json...")
    render_tree([PROJECT_ROOT], configs)

    # Post-panel system config: timezone, firewall, SSH MOTD audit,
    # auto-update cron. Replaces common/run.sh.j2.
    from hiddify_manager.modules.common import apply_runtime_config
    log.info("Applying post-panel system config (timezone, firewall, sshd)...")
    apply_runtime_config(configs)


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


def run_update(mode):
    """
    Update the hiddifypanel package, then re-run the install loop so the
    new code lands in /opt/hiddify-manager and its dependents (templates,
    firewall, services) get reapplied.
    """
    from hiddify_manager.modules.panel_installer import update_panel
    log.info(f"Starting panel update (mode={mode!r})...")
    if not update_panel(mode):
        log.error("Panel update failed; skipping install loop.")
        return
    log.info("Panel update finished; reapplying install loop.")
    run_install()


def run_upgrade(mode):
    """
    Full upgrade: pull the latest hiddify-manager source from GitHub,
    then re-exec ./init.sh update <mode> so the new code drives the
    rest of the flow (panel package + install loop).

    This is what `bash hiddify_installer.sh <mode>` used to do.
    """
    import os
    from hiddify_manager.modules.manager_updater import update_manager_source
    from hiddify_manager.utils.paths import PROJECT_ROOT

    log.info(f"Starting full upgrade (mode={mode!r})...")
    if not update_manager_source(mode):
        log.error("Manager source update failed; skipping panel update.")
        return

    init_sh = os.path.join(PROJECT_ROOT, "init.sh")
    log.info(f"Re-executing {init_sh} update {mode} with the updated source...")
    os.execv(init_sh, [init_sh, "update", mode])


def main():
    parser = argparse.ArgumentParser(description="Hiddify-Manager Configuration Tool")
    parser.add_argument("command", nargs="?",
                        choices=["install", "update", "upgrade", "status", "menu", "migrate"],
                        help="Command to run")
    parser.add_argument("mode", nargs="?", default="release",
                        help="Mode (release/beta/dev/develop/docker/v<tag>); used with `update` and `upgrade`")

    args = parser.parse_args()

    check_root()

    if not args.command or args.command == "menu":
        from hiddify_manager.menu import show_menu
        show_menu()
    elif args.command == "install":
        run_install()
    elif args.command == "update":
        run_update(args.mode)
    elif args.command == "upgrade":
        run_upgrade(args.mode)
    elif args.command == "status":
        log.info("Checking status...")
        from hiddify_manager.modules.services import status
        status()
    elif args.command == "migrate":
        from hiddify_manager.migrate import run_migration
        run_migration()

if __name__ == "__main__":
    main()
