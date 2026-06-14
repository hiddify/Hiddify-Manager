"""
Trigger a usage refresh on the panel.

Replaces hiddify-panel/update_usage.sh: try the local HTTP API first
(`/api/v2/admin/update_user_usage/`), fall back to the in-process
`hiddifypanel update-usage` CLI if the API returns non-200 AND no
update-usage process is already running.

Invoked from the panel through common/commander.py (the
update-wg-usage cron job calls it every minute).
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import CURRENT_JSON, PROJECT_ROOT, VENV_DIR
from hiddify_manager.utils.shell import run_cmd


LOCK_DIR = os.path.join(PROJECT_ROOT, "log")
LOCK_TTL = 120  # seconds — matches the legacy set_lock check


class LockBusy(RuntimeError):
    pass


def _set_lock(name):
    """
    Raise LockBusy if a lock < LOCK_TTL old exists; otherwise stamp it.
    Mirrors common/utils.sh::set_lock.
    """
    os.makedirs(LOCK_DIR, exist_ok=True)
    path = os.path.join(LOCK_DIR, f"{name}.lock")
    if os.path.exists(path):
        try:
            stamp = int(open(path).read().strip() or 0)
        except (ValueError, OSError):
            stamp = 0
        if time.time() - stamp < LOCK_TTL:
            raise LockBusy(f"{name} lock held (<{LOCK_TTL}s old)")
    with open(path, "w") as f:
        f.write(str(int(time.time())))


def _remove_lock(name):
    path = os.path.join(LOCK_DIR, f"{name}.lock")
    try:
        os.remove(path)
    except OSError:
        pass


def _panel_http_api(endpoint):
    """
    Hit the local panel via api_path + api_key (both pulled from
    current.json). Returns (http_status_int, body_bytes); raises on the
    "config not found" / "fields missing" cases that the bash helper
    would have echo'd "invalid config file" for.
    """
    if not os.path.exists(CURRENT_JSON):
        raise FileNotFoundError(f"{CURRENT_JSON} not present")
    with open(CURRENT_JSON) as f:
        cfg = json.load(f)
    api_path = cfg.get("api_path") or ""
    api_key = cfg.get("api_key") or ""
    if not api_path or not api_key:
        raise ValueError("api_path / api_key missing from current.json")

    url = f"http://localhost:9000/{api_path}/api/v2/{endpoint}"
    req = urllib.request.Request(url, headers={"Hiddify-API-Key": api_key})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read() if hasattr(e, "read") else b""
    except urllib.error.URLError as e:
        log.warning(f"update_usage: panel http_api error: {e.reason}")
        return 0, b""


def _is_panel_update_usage_running():
    """
    Equivalent to `pgrep -f 'hiddifypanel update-usage'`. Returns True
    if a python process running that exists, so we skip the CLI fallback
    instead of stomping on it.
    """
    res = run_cmd(
        ["pgrep", "-f", "hiddifypanel update-usage"],
        check=False, capture_output=True,
    )
    return res.returncode == 0


def _cli_fallback():
    venv_python = os.path.join(VENV_DIR, "bin", "python3")
    run_cmd([venv_python, "-m", "hiddifypanel", "update-usage"], check=False)


def run():
    """Top-level: try HTTP, fall back to CLI when needed. Caller holds the lock."""
    try:
        status, body = _panel_http_api("admin/update_user_usage/")
    except Exception as e:
        log.error(f"update_usage: panel http_api unavailable: {e}")
        status = 0
        body = b""
    if status == 200:
        log.info(f"update_usage: http_api OK ({len(body)} bytes)")
        return 0
    log.info(f"update_usage: http_api returned status={status}; falling back to CLI")
    if _is_panel_update_usage_running():
        log.info("update_usage: CLI already running — skipping fallback")
        return 0
    _cli_fallback()
    return 0


def main():
    try:
        _set_lock("update_usage")
    except LockBusy as e:
        log.info(f"update_usage: {e}")
        return 0
    try:
        return run()
    finally:
        _remove_lock("update_usage")


if __name__ == "__main__":
    sys.exit(main())
