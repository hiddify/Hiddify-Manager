import argparse
from utils.logger import log
from utils.shell import run_cmd

def main():
    parser = argparse.ArgumentParser(description="Hiddify-Manager Configuration Tool")
    parser.add_argument("command", choices=["install", "update", "status"], help="Command to run")
    
    args = parser.parse_args()
    
    log.info(f"Hiddify-Manager started with command: {args.command}")
    
    if args.command == "install":
        log.info("Starting installation...")
        # TODO: Phase 2 orchestration logic will go here
    elif args.command == "update":
        log.info("Starting update...")
        # TODO: Update logic
    elif args.command == "status":
        log.info("Checking status...")
        # TODO: Status logic

if __name__ == "__main__":
    main()
