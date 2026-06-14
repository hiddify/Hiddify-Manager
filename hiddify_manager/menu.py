"""
Interactive operator menu — `./init.sh menu` (or just `hiddify`).

questionary's `use_shortcuts=True` assigns 1-9 keys automatically;
we set `shortcut_key=` on each Choice so memorable letters work too
("q" to quit, "s" for status, etc.). Output uses rich.Console so the
menu prompts aren't decorated with logger timestamps.
"""
import sys

import questionary
from rich.console import Console

console = Console()


def _wait_to_return():
    questionary.text("Press Enter to return...").ask()


def _run_choice(choice):
    """Handle a top-level menu choice. Returns True to keep looping, False to exit."""
    if choice in (None, "quit"):
        return False
    if choice == "status":
        from hiddify_manager.modules.services import status
        status()
    elif choice == "admin":
        from hiddify_manager.modules.admin_links import show
        show()
    elif choice == "log":
        from hiddify_manager.modules.logs import browse
        browse()
    elif choice == "restart":
        from hiddify_manager.modules.services import restart
        restart()
    elif choice == "install":
        from hiddify_manager.manager import run_install
        run_install()
    elif choice == "update":
        from hiddify_manager.manager import run_update
        run_update("release")
    elif choice == "advanced":
        show_advanced_menu()
        return True  # advanced has its own "press enter" prompts
    _wait_to_return()
    return True


def show_menu():
    while True:
        choice = questionary.select(
            "Hiddify Manager",
            choices=[
                questionary.Choice("View status of system",       value="status",   shortcut_key="s"),
                questionary.Choice("Show admin link",             value="admin",    shortcut_key="a"),
                questionary.Choice("View system logs",            value="log",      shortcut_key="l"),
                questionary.Choice("Restart services",            value="restart",  shortcut_key="r"),
                questionary.Choice("Reinstall the server",        value="install",  shortcut_key="i"),
                questionary.Choice("Update",                      value="update",   shortcut_key="u"),
                questionary.Choice("Advanced (Uninstall, Remote Assistant, ...)",
                                                                  value="advanced", shortcut_key="x"),
                questionary.Choice("Quit",                        value="quit",     shortcut_key="q"),
            ],
            use_shortcuts=True,
        ).ask()
        if not _run_choice(choice):
            sys.exit(0)


def show_advanced_menu():
    choice = questionary.select(
        "Advanced Options",
        choices=[
            questionary.Choice("Check WARP status",         value="warp",          shortcut_key="w"),
            questionary.Choice("Add remote assistant",      value="add_remote",    shortcut_key="a"),
            questionary.Choice("Remove remote assistant",   value="remove_remote", shortcut_key="r"),
            questionary.Choice("Uninstall",                 value="uninstall",     shortcut_key="u"),
            questionary.Choice("Back",                      value="back",          shortcut_key="b"),
        ],
        use_shortcuts=True,
    ).ask()

    if choice == "warp":
        from hiddify_manager.modules.warp import _real_test
        if _real_test():
            console.print("[green]WARP is WORKING[/green]")
        else:
            console.print("[yellow]WARP is NOT working[/yellow]")
    elif choice == "add_remote":
        from hiddify_manager.modules.remote_assistant import add as add_assistant
        add_assistant()
    elif choice == "remove_remote":
        from hiddify_manager.modules.remote_assistant import remove as remove_assistant
        remove_assistant()
    elif choice == "uninstall":
        confirm = questionary.confirm(
            "This will stop + disable every hiddify-managed unit and clear hiddify-* crons. Continue?",
            default=False,
        ).ask()
        if confirm:
            from hiddify_manager.uninstall import run as run_uninstall
            run_uninstall(purge=False)

    if choice != "back":
        _wait_to_return()
