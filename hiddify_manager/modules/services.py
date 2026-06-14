"""
restart() and status() for the systemd units managed by Hiddify-Manager.

Replaces restart.sh + status.sh. Both legacy scripts globbed
**/*.service files under the project tree to discover units; we
mirror that with pathlib + a small set of external units (mariadb,
wg-quick@warp, mtproxy*) that the bash also hard-coded.

restart() restarts in three waves so dependency-y units don't race:
  1. everything except hiddify-panel*, hiddify-cli
  2. hiddify-panel + hiddify-panel-background-tasks
  3. hiddify-cli

status() walks the same set and prints a one-line-per-unit table.
"""
import os
from concurrent.futures import ThreadPoolExecutor

from hiddify_manager.utils.config import hiddify_config
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import PROJECT_ROOT
from hiddify_manager.utils.shell import run_cmd


EXTERNAL_UNITS = ("mariadb", "wg-quick@warp", "mtproxy.service", "mtproto-proxy.service")
PANEL_UNITS = ("hiddify-panel", "hiddify-panel-background-tasks")
CLI_UNITS = ("hiddify-cli",)

# Glob roots — mirrors the legacy `other/**/*.service **/*.service`.
_SERVICE_GLOBS = (
    os.path.join(PROJECT_ROOT, "**", "*.service"),
)


def _unit_name(path_or_unit):
    """Strip dir + .service suffix. 'a/b/foo.service' -> 'foo', 'foo' -> 'foo'."""
    base = os.path.basename(path_or_unit)
    return base.split(".", 1)[0]


def discover_units():
    """All systemd units we manage. Deterministic order; dedups by name."""
    import glob
    found = set()
    for pattern in _SERVICE_GLOBS:
        for path in glob.glob(pattern, recursive=True):
            # Skip the .venv and the panel's bundled src files.
            if ".venv" in path or "/hiddify-panel/src/" in path:
                continue
            found.add(_unit_name(path))
    for unit in EXTERNAL_UNITS:
        found.add(unit)
    return sorted(found)


def _warp_enabled():
    """Mirror the bash check: skip wg-quick@warp if panel says warp_mode == 'disable'."""
    configs = hiddify_config()
    if not configs:
        return True  # be conservative — touch the unit anyway
    mode = ((configs.get("hconfigs") or {}).get("warp_mode") or "").lower()
    return mode != "disable"


def _is_enabled(unit):
    res = run_cmd(["systemctl", "is-enabled", unit], check=False, capture_output=True, quiet=True)
    return res.returncode == 0


def _is_active(unit):
    res = run_cmd(["systemctl", "is-active", unit], check=False, capture_output=True, quiet=True)
    return (res.stdout or "").strip()


def _should_skip(unit):
    """warp filter — applied to both restart and status."""
    if unit == "wg-quick@warp" and not _warp_enabled():
        return True
    return False


def _restart_unit(unit):
    if _should_skip(unit) or not _is_enabled(unit):
        return None
    before = _is_active(unit)
    run_cmd(["systemctl", "restart", unit], check=False, quiet=True)
    after = _is_active(unit)
    return (unit, before, after)


def _restart_group(units, max_workers=8):
    rows = []
    with ThreadPoolExecutor(max_workers=max_workers) as pool:
        for row in pool.map(_restart_unit, units):
            if row:
                rows.append(row)
    return rows


def _print_table(headers, rows, status_col_idx=None):
    """Print a fixed-width table to stdout (no log timestamp prefix)."""
    from rich.console import Console
    from rich.table import Table

    table = Table(show_header=True, header_style="bold cyan")
    for h in headers:
        table.add_column(h)
    for row in rows:
        formatted = []
        for i, cell in enumerate(row):
            text = str(cell)
            if status_col_idx is not None and i == status_col_idx:
                if text == "active":
                    text = f"[green]{text}[/green]"
                elif text in ("inactive", "failed"):
                    text = f"[red]{text}[/red]"
                else:
                    text = f"[yellow]{text}[/yellow]"
            formatted.append(text)
        table.add_row(*formatted)
    Console().print(table)


def restart():
    """Restart every managed unit in three waves and return the status rows."""
    all_units = discover_units()
    panel_set = set(PANEL_UNITS) | set(CLI_UNITS)
    others = [u for u in all_units if u not in panel_set]
    panel = [u for u in PANEL_UNITS if u in all_units or u in PANEL_UNITS]
    cli = [u for u in CLI_UNITS if u in all_units or u in CLI_UNITS]

    rows = []
    rows.extend(_restart_group(others))
    rows.extend(_restart_group(panel))
    rows.extend(_restart_group(cli))

    _print_table(["Name", "Before", "After"], rows, status_col_idx=2)
    return rows


def status():
    """Print one row per enabled unit with its current is-active state."""
    rows = []
    for unit in discover_units():
        if _should_skip(unit) or not _is_enabled(unit):
            continue
        rows.append((unit, _is_active(unit)))

    _print_table(["Service", "Status"], rows, status_col_idx=1)
    return rows
