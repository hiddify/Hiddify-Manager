import os
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.paths import module_dir as _module_dir
import glob

def install():
    module_dir = _module_dir("haproxy")
    
    for template in glob.glob(os.path.join(module_dir, "*.template")):
        os.remove(template)
        
    run_cmd(["systemctl", "stop", "hiddify-sniproxy"], check=False)
    run_cmd(["systemctl", "disable", "hiddify-sniproxy"], check=False)
    run_cmd(["pkill", "-9", "sniproxy"], check=False)
    
    run_cmd(["add-apt-repository", "-y", "ppa:vbernat/haproxy-3.0"], check=False)
    run_cmd(["apt-get", "update", "-y"], check=False)
    run_cmd(["apt-get", "install", "-y", "haproxy"])
    
    run_cmd(["systemctl", "kill", "haproxy"], check=False)
    run_cmd(["systemctl", "stop", "haproxy"], check=False)
    run_cmd(["systemctl", "disable", "haproxy"], check=False)
    
    svc_file = os.path.join(module_dir, "hiddify-haproxy.service")
    if os.path.exists(svc_file):
        run_cmd(["ln", "-sf", svc_file, "/etc/systemd/system/hiddify-haproxy.service"])
        run_cmd(["systemctl", "enable", "hiddify-haproxy.service"])
    log.info("HAProxy setup complete.")
