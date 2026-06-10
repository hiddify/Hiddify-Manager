import os
import shutil
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.paths import module_dir as _module_dir

def install():
    module_dir = _module_dir("nginx")
    
    run_cmd(["useradd", "nginx"], check=False)
    
    run_cmd(["apt-get", "update", "-y"], check=False)
    run_cmd(["apt-get", "install", "-y", "nginx"])
    
    services_to_kill = ["nginx", "apache2"]
    for svc in services_to_kill:
        run_cmd(["systemctl", "kill", svc], check=False)
        run_cmd(["systemctl", "disable", svc], check=False)
        
    old_configs = [
        "/etc/nginx/conf.d/web.conf",
        "/etc/nginx/sites-available/default",
        "/etc/nginx/sites-enabled/default",
        "/etc/nginx/conf.d/default.conf",
        "/etc/nginx/conf.d/xray-base.conf",
        "/etc/nginx/conf.d/speedtest.conf"
    ]
    for cfg in old_configs:
        if os.path.exists(cfg):
            os.remove(cfg)
            
    os.makedirs(os.path.join(module_dir, "run"), exist_ok=True)
    
    hiddify_nginx_svc = os.path.join(module_dir, "hiddify-nginx.service")
    if os.path.exists(hiddify_nginx_svc):
        run_cmd(["ln", "-sf", hiddify_nginx_svc, "/etc/systemd/system/hiddify-nginx.service"])
        run_cmd(["systemctl", "enable", "hiddify-nginx.service"])
    log.info("Nginx setup complete.")
