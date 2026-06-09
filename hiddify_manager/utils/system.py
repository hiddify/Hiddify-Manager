import os
import sys
from .logger import log

def check_root():
    """Ensure the script is running as root."""
    if os.geteuid() != 0:
        log.error("This script must be run by root")
        sys.exit(1)
