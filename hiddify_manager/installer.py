import os
import importlib
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.shell import run_cmd
from hiddify_manager.utils.paths import module_dir as _module_dir

def install_module(module_name, enable=True):
    """
    Simulates the bash `install_run` function.
    """
    if not enable:
        log.info(f"Skipping module {module_name} (disabled)")
        return
        
    log.info(f"======================{module_name}=====================================")
    
    # Check for python module. Use basename so paths like "other/redis"
    # resolve to hiddify_manager.modules.redis instead of an invalid dotted
    # path with a slash in it.
    try:
        short = os.path.basename(module_name)
        py_module_name = f"hiddify_manager.modules.{short.replace('-', '_').replace('.', '_')}"
        py_module = importlib.import_module(py_module_name)
        if hasattr(py_module, 'install'):
            log.info(f"Running Python installer for {module_name}")
            try:
                py_module.install()
            except Exception as e:
                log.exception(f"Python installer for {module_name} raised: {e} — continuing")
            log.info(f"}}========================{module_name}===================================")
            return
    except ImportError:
        pass # Fallback to bash
    
    # Path to the module directory relative to the repository root
    module_dir = _module_dir(module_name)
    
    if not os.path.exists(module_dir):
        log.error(f"Module directory does not exist: {module_dir}")
        return
    
    # Match legacy bash runsh(): per-script failures are logged but don't
    # abort the install loop. Idempotency bugs in individual scripts (e.g.
    # an `mv` on an already-renamed file) shouldn't kill the whole install.
    install_script = os.path.join(module_dir, "install.sh")
    if os.path.exists(install_script):
        log.info(f"===install.sh {module_name}")
        res = run_cmd(["bash", "install.sh"], cwd=module_dir, check=False)
        if getattr(res, "returncode", 0) != 0:
            log.error(f"install.sh for {module_name} exited {res.returncode} — continuing")

    run_script = os.path.join(module_dir, "run.sh")
    if os.path.exists(run_script):
        log.info(f"===run.sh {module_name}")
        res = run_cmd(["bash", "run.sh"], cwd=module_dir, check=False)
        if getattr(res, "returncode", 0) != 0:
            log.error(f"run.sh for {module_name} exited {res.returncode} — continuing")

    log.info(f"}}========================{module_name}===================================")
