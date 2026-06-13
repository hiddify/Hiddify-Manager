import os
import shutil
from urllib.request import urlretrieve
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.paths import (
    module_dir as _module_dir, PROJECT_ROOT, LOG_DIR, VENV_DIR,
)

def check_file_age_days(filepath, days=1):
    import time
    if not os.path.exists(filepath):
        return True
    return (time.time() - os.path.getmtime(filepath)) > (days * 86400)


def _read_mysql_password():
    """The mysql module writes the panel's db password to other/mysql/mysql_pass."""
    pw_file = os.path.join(_module_dir("other/mysql"), "mysql_pass")
    if not os.path.exists(pw_file):
        return None
    with open(pw_file) as f:
        return f.read().strip() or None


def _read_redis_password():
    """Parse `requirepass <pw>` out of other/redis/redis.conf."""
    conf = os.path.join(_module_dir("other/redis"), "redis.conf")
    if not os.path.exists(conf):
        return None
    with open(conf) as f:
        for line in f:
            parts = line.strip().split(None, 1)
            if len(parts) == 2 and parts[0] == "requirepass":
                return parts[1]
    return None


def _set_app_cfg_keys(cfg_path, kv):
    """
    Rewrite cfg_path so that, for each KEY in kv, any existing line starting
    with 'KEY' (mirrors `sed -i '/^KEY/d'`) is dropped and replaced with the
    given value at the bottom. Keeps the rest of the file intact.

    Writes atomically via tempfile + os.replace so a crash mid-write can't
    leave the panel with a half-truncated app.cfg.
    """
    existing = []
    if os.path.exists(cfg_path):
        with open(cfg_path) as f:
            existing = f.readlines()

    keys = list(kv.keys())
    kept = [
        ln for ln in existing
        if not any(ln.lstrip().startswith(k) for k in keys)
    ]
    tail = [f"{k} = '{v}'\n" for k, v in kv.items()]

    tmp = cfg_path + ".tmp"
    with open(tmp, "w") as f:
        f.writelines(kept)
        if kept and not kept[-1].endswith("\n"):
            f.write("\n")
        f.writelines(tail)
    os.chmod(tmp, 0o600)
    os.replace(tmp, cfg_path)

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
            
    # Hand off to bash run.sh for the post-install dance: write app.cfg
    # with the mysql + redis URIs (passwords read from sibling module dirs),
    # run hiddify-panel-cli init-db, import-config from config.env if present,
    # and start the panel + background tasks services.
    #
    # Re-implementing this in python would mean re-deriving the panel's
    # config schema; deferring to run.sh keeps the migration mechanical.
    run_sh = os.path.join(module_dir, "run.sh")
    if os.path.exists(run_sh):
        log.info("Running hiddify-panel run.sh for app.cfg + init-db")
        res = run_cmd(["bash", "run.sh"], cwd=module_dir, check=False)
        if getattr(res, "returncode", 0) != 0:
            log.error(f"hiddify-panel run.sh exited {res.returncode}")

    log.info("Hiddify Panel setup complete.")
