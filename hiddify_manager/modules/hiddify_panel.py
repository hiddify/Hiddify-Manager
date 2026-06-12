import os
import shutil
from urllib.request import urlretrieve
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.paths import module_dir as _module_dir, PROJECT_ROOT, LOG_DIR

def check_file_age_days(filepath, days=1):
    import time
    if not os.path.exists(filepath):
        return True
    return (time.time() - os.path.getmtime(filepath)) > (days * 86400)

def install():
    module_dir = _module_dir("hiddify-panel")
    
    # Dependencies
    run_cmd(["apt-get", "install", "-y", "wireguard", "libev-dev", "libevdev2", "default-libmysqlclient-dev", "build-essential", "pkg-config", "ssh"])
    
    # Create user
    run_cmd(["useradd", "-m", "hiddify-panel", "-s", "/bin/bash"], check=False)
    run_cmd(["usermod", "-aG", "hiddify-common", "hiddify-panel"], check=False)
    
    # Setup logs
    panel_log = os.path.join(LOG_DIR, "panel.log")
    os.makedirs(LOG_DIR, exist_ok=True)
    if not os.path.exists(panel_log):
        with open(panel_log, "w") as f:
            pass
    run_cmd(["chown", "hiddify-panel", panel_log])
    
    run_cmd(["chsh", "hiddify-panel", "-s", "/bin/bash"], check=False)
    
    # Permissions
    run_cmd(["chown", "-R", "hiddify-panel:hiddify-panel", "/home/hiddify-panel/"], check=False)
    run_cmd(["localectl", "set-locale", "LANG=C.UTF-8"], check=False)
    run_cmd(["su", "hiddify-panel", "-c", "update-locale LANG=C.UTF-8"], check=False)
    run_cmd(["chown", "-R", "hiddify-panel:hiddify-panel", module_dir], check=False)
    
    # Venv profile
    bashrc = "/home/hiddify-panel/.bashrc"
    if os.path.exists(bashrc):
        with open(bashrc, "r") as f:
            content = f.read()
        venv_bin = os.path.join(PROJECT_ROOT, ".venv313", "bin")
        if f"source {venv_bin}/activate" not in content:
            with open(bashrc, "a") as f:
                f.write(f"\nsource {venv_bin}/activate\n")
                f.write(f"export PATH={venv_bin}:$PATH\n")
                
    # Systemd services
    svc1 = os.path.join(module_dir, "hiddify-panel.service")
    if os.path.exists(svc1):
        run_cmd(["ln", "-sf", svc1, "/etc/systemd/system/hiddify-panel.service"])
        run_cmd(["systemctl", "enable", "hiddify-panel.service"])
        
    svc2 = os.path.join(module_dir, "hiddify-panel-background-tasks.service")
    if os.path.exists(svc2):
        run_cmd(["ln", "-sf", svc2, "/etc/systemd/system/hiddify-panel-background-tasks.service"])
        run_cmd(["systemctl", "enable", "hiddify-panel-background-tasks.service"])
        
    # Check if we should build from source
    source_dir = os.environ.get("HIDDIFY_PANLE_SOURCE_DIR")
    if source_dir:
        log.info(f"NOTICE: building hiddifypanel package from source dir: {source_dir}")
        run_cmd(["uv", "pip", "install", "-e", source_dir])
        
    # Cron cleanup
    for cron_file in ["hiddify_usage_update", "hiddify_auto_backup"]:
        p = f"/etc/cron.d/{cron_file}"
        if os.path.exists(p):
            os.remove(p)
    run_cmd(["service", "cron", "reload"], check=False)
    
    # GeoLite Databases
    asn_db = os.path.join(module_dir, "GeoLite2-ASN.mmdb")
    if check_file_age_days(asn_db, 1):
        log.info("Downloading GeoLite2-ASN.mmdb...")
        try:
            urlretrieve("https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb", asn_db)
        except Exception as e:
            log.error(f"Failed to download GeoLite2-ASN.mmdb: {e}")
            
    country_db = os.path.join(module_dir, "GeoLite2-Country.mmdb")
    if check_file_age_days(country_db, 1):
        log.info("Downloading GeoLite2-Country.mmdb...")
        try:
            urlretrieve("https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb", country_db)
        except Exception as e:
            log.error(f"Failed to download GeoLite2-Country.mmdb: {e}")
            
    log.info("Hiddify Panel setup complete.")
