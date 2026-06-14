import sys
import questionary
from rich.console import Console
from hiddify_manager.utils.shell import run_cmd

console = Console()

def show_menu():
    while True:
        choice = questionary.select(
            "Hiddify Manager",
            choices=[
                questionary.Choice("View status of system", value="status"),
                questionary.Choice("Show admin link", value="admin"),
                questionary.Choice("View system logs", value="log"),
                questionary.Choice("Restart Services without changing the configs", value="restart"),
                questionary.Choice("Reinstall the server", value="install"),
                questionary.Choice("Update", value="update"),
                questionary.Choice("Advanced (Uninstall, Remote Assistant, ...)", value="advanced"),
                questionary.Choice("Quit", value="quit")
            ]
        ).ask()

        if choice == "quit" or choice is None:
            sys.exit(0)
        elif choice == "status":
            from hiddify_manager.modules.services import status
            status()
            questionary.text("Press Enter to return...").ask()
        elif choice == "admin":
            console.print("[bold yellow]Showing admin link...[/bold yellow]")
            run_cmd(["hiddify-panel-cli", "reset-owner-password"], check=False)
            questionary.text("Press Enter to return...").ask()
        elif choice == "log":
            console.print("[bold cyan]System Logs:[/bold cyan]")
            run_cmd(["ls", "-lah", "log/system/"], check=False)
            questionary.text("Press Enter to return...").ask()
        elif choice == "restart":
            from hiddify_manager.modules.services import restart
            restart()
            questionary.text("Press Enter to return...").ask()
        elif choice == "install":
            from hiddify_manager.manager import run_install
            run_install()
            questionary.text("Press Enter to return...").ask()
        elif choice == "update":
            from hiddify_manager.manager import run_update
            run_update("release")
            questionary.text("Press Enter to return...").ask()
        elif choice == "advanced":
            show_advanced_menu()

def show_advanced_menu():
    choice = questionary.select(
        "Advanced Options",
        choices=[
            questionary.Choice("Check Warp Status", value="warp"),
            questionary.Choice("Add remote assistant", value="add_remote"),
            questionary.Choice("Remove remote assistant", value="remove_remote"),
            questionary.Choice("Uninstall", value="uninstall"),
            questionary.Choice("Back", value="back")
        ]
    ).ask()
    
    if choice == "warp":
        # other/warp/status.sh is gone; the WARP probe lives in
        # the python warp module now. Re-run the install path,
        # which validates connectivity as part of bring-up.
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
        from hiddify_manager.uninstall import run as run_uninstall
        run_uninstall(purge=False)
        
    if choice != "back":
        questionary.text("Press Enter to return...").ask()
