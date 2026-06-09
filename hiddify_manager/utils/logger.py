import logging
import sys

def setup_logger():
    logger = logging.getLogger("hiddify_manager")
    logger.setLevel(logging.INFO)
    
    # Console handler
    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(logging.INFO)
    
    # Formatter
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
    ch.setFormatter(formatter)
    
    logger.addHandler(ch)
    return logger

log = setup_logger()
