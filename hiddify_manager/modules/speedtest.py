import os

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import module_dir as _module_dir


CHUNK = 1024 * 1024
SIZE_MB = 30


def install():
    """Create the 30 MB random blob served as the upload/download target."""
    module_dir = _module_dir("other/speedtest")
    os.makedirs(module_dir, exist_ok=True)
    target = os.path.join(module_dir, "downloading")
    if os.path.exists(target) and os.path.getsize(target) >= SIZE_MB * CHUNK:
        log.info("speedtest blob already present, skipping")
        return
    log.info(f"generating {SIZE_MB}MB speedtest blob at {target}")
    with open(target, "wb") as f:
        for _ in range(SIZE_MB):
            f.write(os.urandom(CHUNK))
