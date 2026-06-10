"""
Dynamic path resolution for Hiddify-Manager.

All path references should go through this module instead of
hardcoding /opt/hiddify-manager or other absolute paths.
"""
import os

# Project root = parent of hiddify_manager/ package
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Common sub-directories
LOG_DIR = os.path.join(PROJECT_ROOT, "log", "system")
COMMON_DIR = os.path.join(PROJECT_ROOT, "common")
PACKAGES_LOCK = os.path.join(COMMON_DIR, "packages.lock")


def module_dir(module_name: str) -> str:
    """Return the absolute path to a module's directory (e.g. 'xray', 'other/warp')."""
    return os.path.join(PROJECT_ROOT, module_name)


def ensure_dirs():
    """Create standard directories if they don't exist."""
    os.makedirs(LOG_DIR, exist_ok=True)
