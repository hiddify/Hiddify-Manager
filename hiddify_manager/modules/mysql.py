import os
import secrets
import string
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.paths import module_dir as _module_dir

def generate_random_password(length=49):
    chars = string.ascii_letters + string.digits
    return ''.join(secrets.choice(chars) for _ in range(length))

def install():
    module_dir = _module_dir("other/mysql")
    os.makedirs(module_dir, exist_ok=True)
    
    run_cmd(["apt-get", "install", "-y", "mariadb-server"])
    
    pass_file = os.path.join(module_dir, "mysql_pass")
    
    if not os.path.exists(pass_file):
        log.info("Generating a random password for MySQL...")
        random_password = generate_random_password()
        with open(pass_file, "w") as f:
            f.write(random_password + "\n")
        os.chmod(pass_file, 0o600)
        
        # Secure MariaDB installation via input
        secure_install_input = f"y\n{random_password}\n{random_password}\ny\ny\ny\ny\n"
        run_cmd(["mysql_secure_installation"], input_data=secure_install_input, check=False)
        
        mariadb_conf = "/etc/mysql/mariadb.conf.d/50-server.cnf"
        if os.path.exists(mariadb_conf):
            # Disable external access
            run_cmd(["sed", "-i", "s/bind-address/#bind-address/", mariadb_conf], check=False)
        
        run_cmd(["systemctl", "restart", "mariadb"], check=False)
        
        # SQL fed via stdin (not argv); password is escaped defensively so
        # this remains safe if generate_random_password() ever yields ' or \.
        escaped = random_password.replace("\\", "\\\\").replace("'", "\\'")
        sql_script = (
            f"CREATE USER IF NOT EXISTS 'hiddifypanel'@'localhost' IDENTIFIED BY '{escaped}';"
            f"ALTER USER 'hiddifypanel'@'localhost' IDENTIFIED BY '{escaped}';"
            "GRANT ALL PRIVILEGES ON *.* TO 'hiddifypanel'@'localhost';"
            "CREATE DATABASE IF NOT EXISTS hiddifypanel "
            "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
            "GRANT ALL PRIVILEGES ON hiddifypanel.* TO 'hiddifypanel'@'localhost';"
            "FLUSH PRIVILEGES;"
        )
        run_cmd(["mysql", "-u", "root", "-f"], input_data=sql_script, check=False)
        log.info("MariaDB setup complete.")
        
    mariadb_conf = "/etc/mysql/mariadb.conf.d/50-server.cnf"
    if os.path.exists(mariadb_conf):
        # Check if bind-address is already set to 127.0.0.1
        grep_res = run_cmd(["grep", "-q", r"^[^#]*bind-address\s*=\s*127.0.0.1", mariadb_conf], check=False)
        if grep_res.returncode != 0:
            grep_comment = run_cmd(["grep", "-q", r"^#\+bind-address", mariadb_conf], check=False)
            if grep_comment.returncode == 0:
                run_cmd(["sed", "-i", r"s/^#\+bind-address\s*=\s*[0-9.]*/bind-address = 127.0.0.1/", mariadb_conf], check=False)
            else:
                run_cmd(["sed", "-i", r"/\[mysqld\]/a bind-address = 127.0.0.1", mariadb_conf], check=False)
            log.info(f"bind-address set to 127.0.0.1 in {mariadb_conf}")
            run_cmd(["systemctl", "restart", "mariadb"], check=False)
    else:
        log.warning(f"MariaDB configuration file ({mariadb_conf}) not found.")
        
    run_cmd(["systemctl", "start", "mariadb"], check=False)
    run_cmd(["systemctl", "enable", "mariadb"], check=False)
