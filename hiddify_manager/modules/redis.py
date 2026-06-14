import os
import secrets
import string
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.paths import module_dir as _module_dir, LOG_DIR

def generate_random_password(length=49):
    chars = string.ascii_letters + string.digits
    return ''.join(secrets.choice(chars) for _ in range(length))

def install():
    module_dir = _module_dir("other/redis")
    
    check_installed = run_cmd(["dpkg", "-s", "redis-server"], check=False)
    if check_installed.returncode != 0:
        run_cmd(["add-apt-repository", "-y", "universe"], check=False)
        run_cmd(["apt-get", "install", "-y", "redis-server"])
        
    # STOP any running system redis first to avoid a window without a password
    run_cmd(["systemctl", "disable", "--now", "redis-server"], check=False)
    run_cmd(["pkill", "-9", "redis-server"], check=False)
    
    if os.path.exists(module_dir):
        run_cmd(["chown", "-R", "redis:redis", module_dir])
    
    redis_conf = os.path.join(module_dir, "redis.conf")
    if os.path.exists(redis_conf):
        os.chmod(redis_conf, 0o600)
        
        # Ensure a password exists in repo config before starting any service
        with open(redis_conf, "r") as f:
            content = f.read()
            
        if not any(line.startswith("requirepass") for line in content.splitlines()):
            random_password = generate_random_password()
            with open(redis_conf, "a") as f:
                f.write(f"\nrequirepass {random_password}\n")
            log.info("Generated a random password for Redis.")
            
    # Wire up and start the managed service using the repo config
    svc_file = os.path.join(module_dir, "hiddify-redis.service")
    if os.path.exists(svc_file):
        run_cmd(["ln", "-sf", svc_file, "/etc/systemd/system/hiddify-redis.service"])
        run_cmd(["systemctl", "enable", "--now", "hiddify-redis"])
        
    # Ensure logging path exists/owned
    redis_log = os.path.join(LOG_DIR, "redis-server.log")
    os.makedirs(LOG_DIR, exist_ok=True)
    if not os.path.exists(redis_log):
        with open(redis_log, "w") as f:
            pass
    run_cmd(["chown", "redis:redis", redis_log])
    log.info("Redis setup complete.")
