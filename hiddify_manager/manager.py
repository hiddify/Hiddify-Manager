import argparse
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.progress import progress
from hiddify_manager.utils.system import check_root
from hiddify_manager.installer import install_module


# (percent, display name) per module. The percent is the value the panel's
# progress bar should show *while* that module is being installed. Tuned to
# roughly match the legacy install.sh's progression so the UI feels familiar.
_INSTALL_PROGRESS = {
    "common":            (2,  "Common Tools and Requirements"),
    "other/redis":       (8,  "Redis"),
    "other/mysql":       (12, "MySQL"),
    "hiddify-panel":     (20, "Hiddify Panel"),
    "nginx":             (40, "Nginx"),
    "haproxy":           (50, "HAProxy"),
    "acme.sh":           (60, "Getting Certificates"),
    "other/speedtest":   (62, "SpeedTest"),
    "other/dnstt":       (65, "DNStt Proxy"),
    "other/telegram":    (68, "Telegram Proxy"),
    "other/ssfaketls":   (72, "FakeTLS Proxy"),
    "other/ssh":         (75, "SSH Proxy"),
    "other/warp":        (78, "Warp"),
    "xray":              (82, "Xray"),
    "other/hiddify-cli": (86, "HiddifyCli"),
    "other/wireguard":   (90, "Wireguard"),
    "singbox":           (94, "Singbox"),
}


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
    progress(0, "Please wait...", "We are going to install Hiddify")
    modules = [
        "common", "other/redis", "other/mysql", "hiddify-panel",
        "nginx", "haproxy", "acme.sh", "other/speedtest", "other/dnstt",
        "other/telegram", "other/ssfaketls", "other/ssh", "other/warp",
        "xray", "other/hiddify-cli", "other/wireguard", "singbox"
    ]
    for mod in modules:
        pct, label = _INSTALL_PROGRESS.get(mod, (None, None))
        if pct is not None:
            progress(pct, "Installing...", label)
        install_module(mod)
        if mod == "hiddify-panel":
            progress(30, "Configuring...", "Rendering configs + system setup")
            _render_all_templates()
    progress(98, "Almost finished", "Wrapping up")
    log.info("Installation completed successfully.")
    progress(100, "Done", "")


def run_update(mode):
    """
    Update the hiddifypanel package, then re-run the install loop so the
    new code lands in /opt/hiddify-manager and its dependents (templates,
    firewall, services) get reapplied.
    """
    from hiddify_manager.modules.panel_installer import update_panel
    log.info(f"Starting panel update (mode={mode!r})...")
    progress(5, "Updating", f"Hiddify Panel ({mode})")
    if not update_panel(mode):
        log.error("Panel update failed; skipping install loop.")
        progress(100, "Failed", "Panel update failed")
        return
    log.info("Panel update finished; reapplying install loop.")
    run_install()


def run_apply_configs(apply_users_only=False):
    """
    Lightweight "the panel config changed, re-derive everything from it" pass.
    This is what `apply_configs.sh` did in the bash era — called by the
    panel via commander.py on every Apply-Configs / user-add / user-remove.

    Unlike run_install(), no apt installs, no binary downloads. Just:
      1. Force-regenerate current.json from the panel.
      2. Render every *.j2 against the fresh configs.
      3. Re-generate self-signed certs for any new domain.
      4. Re-apply firewall + timezone + sshd audit.
      5. Restart services so they pick up the new configs.

    `apply_users_only=True` (the commander.py `apply-users` route) skips
    the firewall + timezone pass — only users/peers changed, no need to
    touch system-level config.
    """
    import os
    from hiddify_manager.utils.config import generate_current_json, hiddify_config
    from hiddify_manager.utils.template import render_tree
    from hiddify_manager.utils.paths import PROJECT_ROOT
    from hiddify_manager.utils.certs import ensure_self_signed_cert

    log.info(
        f"Applying configs (apply_users_only={apply_users_only})..."
    )
    progress(5, "Applying configs", "Reading from panel")

    # Force a fresh current.json — without this the panel's new state
    # wouldn't be visible until something else triggered regeneration.
    if not generate_current_json():
        log.error("apply_configs: could not regenerate current.json — aborting")
        progress(100, "Failed", "Couldn't regenerate current.json")
        return

    configs = hiddify_config()
    if not configs:
        log.error("apply_configs: current.json present but unreadable — aborting")
        progress(100, "Failed", "current.json unreadable")
        return

    progress(20, "Generating certs", "Per-domain self-signed")
    ssl_dir = os.path.join(PROJECT_ROOT, "ssl")
    for d in (configs.get("domains") or []):
        domain = d.get("domain") if isinstance(d, dict) else None
        if domain:
            ensure_self_signed_cert(domain, ssl_dir)

    progress(40, "Rendering", "All *.j2 templates")
    log.info("Rendering all *.j2 templates against current.json...")
    render_tree([PROJECT_ROOT], configs)

    if not apply_users_only:
        from hiddify_manager.modules.common import apply_runtime_config
        progress(70, "Applying", "Firewall, timezone, sshd")
        log.info("Re-applying system config (firewall, timezone, sshd)...")
        apply_runtime_config(configs)

    from hiddify_manager.modules.services import restart
    progress(85, "Restarting services", "")
    log.info("Restarting services...")
    restart()
    progress(100, "Done", "Configs applied")


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
                        choices=["install", "update", "upgrade", "status", "menu",
                                 "migrate", "apply-configs", "apply-users", "restart"],
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
    elif args.command == "restart":
        from hiddify_manager.modules.services import restart
        restart()
    elif args.command == "apply-configs":
        run_apply_configs(apply_users_only=False)
    elif args.command == "apply-users":
        run_apply_configs(apply_users_only=True)
    elif args.command == "migrate":
        from hiddify_manager.migrate import run_migration
        run_migration()

if __name__ == "__main__":
    main()
