import os
import json
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.paths import CURRENT_JSON, VENV_DIR
from hiddify_manager.utils.logger import log

def generate_current_json():
    """Generates current.json by calling hiddifypanel all-configs"""
    venv_python = os.path.join(VENV_DIR, "bin", "python3")

    with open(CURRENT_JSON, "w") as out:
        res = run_cmd(
            [venv_python, "-m", "hiddifypanel", "all-configs"],
            check=False,
            stdout=out,
        )
    if res.returncode == 0:
        os.chmod(CURRENT_JSON, 0o600)
        return True

    log.error("Failed to generate current.json using hiddifypanel cli.")
    return False

def load_configs():
    if not os.path.exists(CURRENT_JSON):
        if not generate_current_json():
            return None

    with open(CURRENT_JSON, "r") as f:
        try:
            return json.load(f)
        except json.JSONDecodeError:
            log.error("current.json is corrupted")
            return None

def hconfig(key):
    """
    Retrieves a configuration value from the panel configs.
    Equivalent to the bash hconfig() function.
    """
    data = load_configs()
    if not data:
        return None
        
    try:
        # The bash script looks in .chconfigs["0"]
        chconfigs = data.get("chconfigs", {})
        config_0 = chconfigs.get("0", {})
        
        if key in config_0:
            return config_0[key]
            
        log.warning(f"Config key not found: {key}")
        return None
    except Exception as e:
        log.error(f"Error parsing hconfig: {e}")
        return None

def hiddify_config():
    """Returns the full data dictionary for templating."""
    return load_configs()
