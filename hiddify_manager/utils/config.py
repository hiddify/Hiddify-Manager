import os
import json
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.paths import CURRENT_JSON, VENV_DIR, PROJECT_ROOT
from hiddify_manager.utils.logger import log


PANEL_DIR = os.path.join(PROJECT_ROOT, "hiddify-panel")

def generate_current_json():
    """Generates current.json by calling hiddifypanel all-configs.

    Writes to a tempfile first; only renames into place if the CLI exits 0
    and the output is parseable JSON. Otherwise the existing current.json
    (if any) is preserved instead of being replaced by an empty/garbled file.
    """
    venv_python = os.path.join(VENV_DIR, "bin", "python3")
    tmp_path = CURRENT_JSON + ".tmp"

    # cwd must be the panel dir so hiddifypanel picks up ./app.cfg
    # (which holds SQLALCHEMY_DATABASE_URI / REDIS_URI_MAIN).
    with open(tmp_path, "w") as out:
        res = run_cmd(
            [venv_python, "-m", "hiddifypanel", "all-configs"],
            check=False,
            stdout=out,
            cwd=PANEL_DIR,
        )
    if res.returncode != 0:
        log.error(f"hiddifypanel all-configs exited {res.returncode}")
        try: os.unlink(tmp_path)
        except OSError: pass
        return False

    # Validate JSON before replacing the live file.
    try:
        with open(tmp_path) as f:
            json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        log.error(f"hiddifypanel all-configs produced invalid JSON: {e}")
        try: os.unlink(tmp_path)
        except OSError: pass
        return False

    os.replace(tmp_path, CURRENT_JSON)
    os.chmod(CURRENT_JSON, 0o600)
    return True

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
