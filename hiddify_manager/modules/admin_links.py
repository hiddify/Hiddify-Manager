"""
Print the panel's admin links to the operator.

Replaces the previous menu entry that called `hiddify-panel-cli
reset-owner-password` (which 1) doesn't exist on PATH and 2) is
destructive — it resets the admin password, which is not what
"Show admin link" should do).

Read panel_links straight from current.json and colour them per the
legacy check_hiddify_panel rules:

  http://*      -> red    [insecure]
  https://<ip>/ -> yellow [self-signed]
  otherwise     -> green  (real cert)
"""
import json
import re

from rich.console import Console

from hiddify_manager.utils.paths import CURRENT_JSON


_IPV4_HOST_RE = re.compile(r"^https://(?:.+@)?\d+\.\d+\.\d+\.\d+(?::\d+)?/")


def _classify(link):
    if link.startswith("http://"):
        return "[insecure]", "red"
    if _IPV4_HOST_RE.match(link):
        return "[self-signed]", "yellow"
    return "", "green"


def show():
    console = Console()
    try:
        with open(CURRENT_JSON) as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        console.print(f"[red]admin_links: can't read {CURRENT_JSON}: {e}[/red]")
        return 1

    links = data.get("panel_links") or []
    if not links:
        console.print("[yellow]admin_links: no panel_links in current.json[/yellow]")
        return 1

    console.print("[bold]Admin links:[/bold]")
    for link in links:
        tag, colour = _classify(link)
        prefix = f"{tag} " if tag else ""
        console.print(f"  [{colour}]{prefix}{link}[/{colour}]")
    return 0
