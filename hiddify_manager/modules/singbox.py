import os
import shutil
import glob
from utils.logger import log
from utils.shell import run_cmd
from utils.package_manager import download_package, extract_package

def install():
    module_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "singbox")
    
    # Clean templates
    configs_dir = os.path.join(module_dir, "configs")
    if os.path.exists(configs_dir):
        for template in glob.glob(os.path.join(configs_dir, "*.template")):
            os.remove(template)
            
    archive_path = os.path.join(module_dir, "sb.tar.gz")
    
    if download_package("singbox", archive_path):
        if extract_package(archive_path, module_dir):
            os.remove(archive_path)
            
            # Extract logic: tarball contains a directory `hiddify-core-*` which needs to be moved to `module_dir`
            extracted_dirs = glob.glob(os.path.join(module_dir, "hiddify-core-*"))
            if extracted_dirs:
                src_dir = extracted_dirs[0]
                for item in os.listdir(src_dir):
                    shutil.move(os.path.join(src_dir, item), module_dir)
                shutil.rmtree(src_dir)
            
            sb_bin = os.path.join(module_dir, "hiddify-core")
            if os.path.exists(sb_bin):
                run_cmd(["chown", "root:root", sb_bin])
                run_cmd(["chmod", "+x", sb_bin])
                
                run_cmd(["ln", "-sf", sb_bin, "/usr/bin/hiddify-core"])
                
                geosite_db = os.path.join(module_dir, "geosite.db")
                if os.path.exists(geosite_db):
                    os.remove(geosite_db)
                    
                log.info("Singbox (hiddify-core) installed successfully.")
            else:
                log.error("hiddify-core binary not found after extraction.")
        else:
            log.error("Failed to extract Singbox.")
    else:
        log.error("Failed to download Singbox.")
