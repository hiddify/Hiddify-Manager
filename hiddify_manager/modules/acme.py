import os
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.shell import run_cmd

def install():
    module_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "acme.sh")
    
    run_cmd(["apt-get", "install", "-y", "socat"])
    run_cmd(["apt-get", "remove", "-y", "certbot"], check=False)
    
    lib_dir = os.path.join(module_dir, "lib")
    os.makedirs(lib_dir, exist_ok=True)
    
    acme_sh_path = os.path.join(lib_dir, "acme.sh")
    if not os.path.exists(acme_sh_path):
        log.info("Downloading acme.sh...")
        install_cmd = f"curl -s -L https://get.acme.sh | sh -s -- home {lib_dir} --config-home {lib_dir}/data --cert-home {lib_dir}/certs --nocron"
        run_cmd(install_cmd, shell=True)
        
    run_cmd([acme_sh_path, "--upgrade"], check=False)
    
    if os.path.exists(acme_sh_path):
        with open(acme_sh_path, 'r') as f:
            content = f.read()
        if 'return 10; fi' not in content:
            content = content.replace(
                '_sleep_overload_retry_sec=$_retryafter',
                '_sleep_overload_retry_sec=$_retryafter; if [[ "$_retryafter" > 20 ]];then return 10; fi'
            )
            with open(acme_sh_path, 'w') as f:
                f.write(content)
                
    os.makedirs(os.path.join(os.path.dirname(module_dir), "ssl"), exist_ok=True)
    
    run_cmd([acme_sh_path, "--uninstall-cronjob"], check=False)
    
    run_cmd([acme_sh_path, "--register-account", "-m", "my@example.com"], check=False)
    run_cmd(["systemctl", "reload", "hiddify-haproxy"], check=False)
    
    log.info("Acme.sh setup complete.")
