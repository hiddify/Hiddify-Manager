import subprocess
from .logger import log

def run_cmd(command, check=True, shell=False, capture_output=False, cwd=None):
    """
    Safely runs a shell command.
    """
    cmd_str = ' '.join(command) if isinstance(command, list) else command
    log.info(f"Running command: {cmd_str}")
    try:
        result = subprocess.run(
            command,
            check=check,
            shell=shell,
            capture_output=capture_output,
            text=True,
            cwd=cwd
        )
        if capture_output and result.stdout:
            log.debug(result.stdout)
        return result
    except subprocess.CalledProcessError as e:
        log.error(f"Command failed with exit code {e.returncode}")
        if capture_output:
            if getattr(e, 'output', None):
                log.error(f"Output: {e.output}")
            if getattr(e, 'stderr', None):
                log.error(f"Error: {e.stderr}")
        if check:
            raise
        return e
