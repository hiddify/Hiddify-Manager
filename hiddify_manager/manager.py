import argparse
from utils.logger import log
from utils.system import check_root
from installer import install_module

def main():
    parser = argparse.ArgumentParser(description="Hiddify-Manager Configuration Tool")
    parser.add_argument("command", choices=["install", "update", "status"], help="Command to run")
    
    args = parser.parse_args()
    
    log.info(f"Hiddify-Manager started with command: {args.command}")
    
    check_root()
    
    if args.command == "install":
        log.info("Starting installation...")
        install_module("common")
        install_module("hiddify-panel")
        # TODO: Add other modules here in future phases
    elif args.command == "update":
        log.info("Starting update...")
        # TODO: Update logic
    elif args.command == "status":
        log.info("Checking status...")
        # TODO: Status logic

if __name__ == "__main__":
    main()
