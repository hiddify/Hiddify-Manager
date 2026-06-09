import os
import importlib
from utils.logger import log
from utils.shell import run_cmd

def install_module(module_name, enable=True):
    """
    Simulates the bash `install_run` function.
    """
    if not enable:
        log.info(f"Skipping module {module_name} (disabled)")
        return
        
    log.info(f"======================{module_name}=====================================")
    
    # Check for python module
    try:
        py_module_name = f"modules.{module_name.replace('-', '_')}"
        py_module = importlib.import_module(py_module_name)
        if hasattr(py_module, 'install'):
            log.info(f"Running Python installer for {module_name}")
            py_module.install()
            log.info(f"}}========================{module_name}===================================")
            return
    except ImportError:
        pass # Fallback to bash
    
    # Path to the module directory relative to the repository root
    module_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), module_name)
    
    if not os.path.exists(module_dir):
        log.error(f"Module directory does not exist: {module_dir}")
        return
    
    install_script = os.path.join(module_dir, "install.sh")
    if os.path.exists(install_script):
        log.info(f"===install.sh {module_name}")
        run_cmd(["bash", "install.sh"], cwd=module_dir)
        
    run_script = os.path.join(module_dir, "run.sh")
    if os.path.exists(run_script):
        log.info(f"===run.sh {module_name}")
        run_cmd(["bash", "run.sh"], cwd=module_dir)

    log.info(f"}}========================{module_name}===================================")
