import os
import shutil
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.package_manager import download_package, extract_package

def install():
    module_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "xray")
    bin_dir = os.path.join(module_dir, "bin")
    run_dir = os.path.join(module_dir, "run")
    
    os.makedirs(bin_dir, exist_ok=True)
    os.makedirs(run_dir, exist_ok=True)
    
    archive_path = os.path.join(module_dir, "sb.zip")
    
    run_cmd(["systemctl", "stop", "hiddify-xray.service"], check=False)
    
    # Remove old bins
    for item in os.listdir(bin_dir):
        item_path = os.path.join(bin_dir, item)
        if os.path.isfile(item_path):
            os.remove(item_path)
        elif os.path.isdir(item_path):
            shutil.rmtree(item_path)
            
    if download_package("xray", archive_path):
        if extract_package(archive_path, bin_dir):
            os.remove(archive_path)
            
            xray_bin = os.path.join(bin_dir, "xray")
            if os.path.exists(xray_bin):
                run_cmd(["chown", "root:root", xray_bin])
                run_cmd(["chmod", "+x", xray_bin])
                
                # Symlink
                run_cmd(["ln", "-sf", xray_bin, "/usr/bin/xray"])
                log.info("Xray installed successfully.")
            else:
                log.error("Xray binary not found after extraction.")
        else:
            log.error("Failed to extract Xray.")
    else:
        log.error("Failed to download Xray.")
