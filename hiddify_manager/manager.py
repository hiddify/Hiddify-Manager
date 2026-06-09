import argparse
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.system import check_root
from hiddify_manager.installer import install_module

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
    log.info("Installation completed successfully.")

def main():
    parser = argparse.ArgumentParser(description="Hiddify-Manager Configuration Tool")
    parser.add_argument("command", nargs="?", choices=["install", "update", "status", "menu"], help="Command to run")
    
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

if __name__ == "__main__":
    main()
