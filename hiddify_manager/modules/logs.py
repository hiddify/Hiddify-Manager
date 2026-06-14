"""
Browse log files under log/system/.

Replaces the menu's old "View system logs" which just ran `ls -lah
log/system/`. Now: list each log with its mtime + size, let the user
pick one, tail the last N lines via rich (so colourised + paged).
"""
import os
import time

import questionary
from rich.console import Console

from hiddify_manager.utils.paths import LOG_DIR


TAIL_LINES = 200


def _list_logs():
    """Return a list of (path, size_bytes, mtime) for every regular file."""
    out = []
    if not os.path.isdir(LOG_DIR):
        return out
    for name in sorted(os.listdir(LOG_DIR)):
        path = os.path.join(LOG_DIR, name)
        if not os.path.isfile(path):
            continue
        st = os.stat(path)
        out.append((path, st.st_size, st.st_mtime))
    return out


def _fmt_size(n):
    for unit in ("B", "K", "M", "G"):
        if n < 1024:
            return f"{n:>4}{unit}"
        n //= 1024
    return f"{n:>4}T"


def _fmt_age(mtime):
    age = time.time() - mtime
    if age < 60:
        return f"{int(age)}s ago"
    if age < 3600:
        return f"{int(age / 60)}m ago"
    if age < 86400:
        return f"{int(age / 3600)}h ago"
    return f"{int(age / 86400)}d ago"


def _tail(path, lines=TAIL_LINES):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            data = f.readlines()
    except OSError as e:
        return f"[red]could not read {path}: {e}[/red]"
    return "".join(data[-lines:])


def browse():
    """Pick a log + tail its last TAIL_LINES lines via rich."""
    console = Console()
    logs = _list_logs()
    if not logs:
        console.print(f"[yellow]No log files under {LOG_DIR}[/yellow]")
        return

    choices = []
    for path, size, mtime in logs:
        name = os.path.basename(path)
        label = f"{name:<40}{_fmt_size(size):>6}  {_fmt_age(mtime):>9}"
        choices.append(questionary.Choice(label, value=path))
    choices.append(questionary.Choice("Back", value=None, shortcut_key="b"))

    pick = questionary.select(
        f"Logs under {LOG_DIR} — pick one to tail last {TAIL_LINES} lines",
        choices=choices, use_shortcuts=True,
    ).ask()
    if not pick:
        return

    console.print(f"\n[bold cyan]── tail -{TAIL_LINES} {pick} ──[/bold cyan]")
    body = _tail(pick)
    # Render as plain text; we don't know the actual format. Could detect
    # .json + use rich Syntax later if useful.
    console.print(body, highlight=False, soft_wrap=False)
