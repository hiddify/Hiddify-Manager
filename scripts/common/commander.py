#!/opt/hiddify-manager/.venv313/bin/python
import os
import re
import subprocess
from urllib.parse import urlparse

import click
from strenum import StrEnum

HIDDIFY_DIR = "/opt/hiddify-manager/"


class Command(StrEnum):
    """The value of each command refers to the command shell file"""

    apply = os.path.join(HIDDIFY_DIR, "scripts/apply_configs.sh")
    install = os.path.join(HIDDIFY_DIR, "scripts/install.sh")
    # reinstall = os.path.join(HIDDIFY_DIR,'reinstall.sh')
    update = os.path.join(HIDDIFY_DIR, "scripts/update.sh")
    status = os.path.join(HIDDIFY_DIR, "scripts/status.sh")
    restart_services = os.path.join(HIDDIFY_DIR, "scripts/restart.sh")
    temporary_short_link = os.path.join(HIDDIFY_DIR, "services/nginx/add2shortlink.sh")
    temporary_access = os.path.join(HIDDIFY_DIR, "services/panel/temporary_access.sh")
    update_usage = os.path.join(HIDDIFY_DIR, "services/panel/update_usage.sh")
    get_cert = os.path.join(HIDDIFY_DIR, "services/acme.sh/get_cert.sh")
    # apply-users command is actually "install.sh apply_users"
    apply_users = os.path.join(HIDDIFY_DIR, "scripts/install.sh")
    id = "id"


def systemd_available() -> bool:
    return os.path.isdir("/run/systemd/system")


def _service_name(unit: str) -> str:
    return unit if unit.endswith(".service") else f"{unit}.service"


def _run_direct(cmd: list[str]) -> None:
    subprocess.run(cmd, shell=False, check=True)


def run_isolated(cmd: list[str], unit: str) -> None:
    """Run *cmd* in a transient systemd unit so it is not in the panel cgroup.

    ``systemctl kill`` / ``systemctl restart hiddify-panel`` SIGTERMs every
    process in that cgroup. apply/install used to be children of the panel
    service, so they died before progress 100 and left the unit failed.
    """
    service = _service_name(unit)
    subprocess.run(
        ["systemctl", "reset-failed", service],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if subprocess.run(["systemctl", "is-active", "--quiet", service], check=False).returncode == 0:
        return
    isolated = [
        "systemd-run",
        f"--unit={unit}",
        "--collect",
        "--wait",
        "--",
        *cmd,
    ]
    try:
        subprocess.run(isolated, shell=False, check=True)
    except FileNotFoundError:
        _run_direct(cmd)


def run(cmd: list[str], unit: str | None = None):
    if unit and systemd_available():
        run_isolated(cmd, unit)
        return
    _run_direct(cmd)


@click.group(chain=True)
def cli():
    pass


@cli.command("id")
def id():
    out = subprocess.check_output(["id"])
    print(out.decode())


@cli.command("apply")
def apply():
    cmd = [Command.apply.value, "--no-gui"]
    run(cmd, unit="hiddify-apply")


@cli.command("install")
def install():
    cmd = [Command.install.value, "--no-gui"]
    run(cmd, unit="hiddify-install")


# @cli.command('reinstall')
# def reinstall():
#     cmd = [Command.reinstall.value]
#     run(cmd)


@cli.command("update")
def update():
    cmd = [Command.update.value, "--no-gui"]
    run(cmd, unit="hiddify-update")


@cli.command("restart-services")
def restart_services():
    cmd = [Command.restart_services.value, "--no-gui"]
    run(cmd)


@cli.command("status")
def status():
    cmd = [Command.status.value, "--no-gui"]
    run(cmd)


def add_temporary_short_link_assert_input(url: str, slug: str) -> None:
    """Returns None if everything is valid otherwise returns an error"""

    assert url, "Error: Invalid value for '--url' / '-u': \"\" is not a valid url"

    assert urlparse(url), f"Error: Invalid value for '--url' / '-u': {url} is an invalid url"

    assert slug, "Error: Invalid value for '-slug' / '-s': \"\" is not a valid slug"

    assert slug.isalnum(), "Error: Invalid value for '-slug' / '-s': \"\" is not a alphanumeric"

    assert is_valid_url(url), f"Error: Invalid character in url: {url}"

    # don't need to sanitize slug but we do for good (we are not lucky)
    assert is_valid_slug(slug), f"Error: Invalid character in slug: {slug}"


def is_valid_url(url) -> bool:
    if not urlparse(url):
        return False

    pattern = r"^[a-zA-Z0-9:/@.-]+$"
    return bool(re.match(pattern, url))


def is_valid_slug(slug) -> bool:
    pattern = r"^[a-zA-Z0-9\-]+$"
    return bool(re.match(pattern, slug))


@cli.command("temporary-short-link")
@click.option("--url", "-u", type=str, help="The url that is going to be short", required=True)
@click.option("--slug", "-s", type=str, help="The secret code", required=True)
@click.option("--period", "-p", type=int, help="The time period that link remains active", required=False)
def add_temporary_short_link(url: str, slug: str, period: int):
    # validate inputs
    add_temporary_short_link_assert_input(url, slug)

    cmd = [Command.temporary_short_link.value, url, slug, str(period)]

    run(cmd)


# @cli.command('temporary-access')
# @click.option('--port', '-p', type=int, help='The port that is going to be open', required=True)
# def add_temporary_access(port: int):
#     cmd = [Command.temporary_access.value, str(port)]
#     run(cmd)


def is_domain_valid(d):
    pattern = r"^[a-zA-Z0-9\-.]+$"
    return bool(re.match(pattern, d))


@cli.command("get-cert")
@click.option("--domain", "-d", type=str, help="The domain that needs certificate", required=True)
def get_cert(domain: str):
    if not domain:
        return
    assert is_domain_valid(domain), f"Error: Invalid domain passed to the get_cert command: {domain}"
    cmd = [Command.get_cert.value, domain]
    run(cmd)


@cli.command("update-usage")
def update_usage():
    cmd = [Command.update_usage.value]
    run(cmd)


@cli.command("apply-users")
def apply_users():
    cmd = [Command.apply_users.value, "apply_users", "--no-gui"]
    run(cmd, unit="hiddify-apply-users")


@cli.command("update-wg-usage")
def update_wg_usage():
    try:
        wg_raw_output = subprocess.check_output(
            ["wg", "show", "hiddifywg", "transfer"],
            stderr=subprocess.DEVNULL,
        )
        print(wg_raw_output.decode())
    except (FileNotFoundError, subprocess.CalledProcessError):
        # Interface not up yet (common in Docker / before wg-quick).
        pass


if __name__ == "__main__":
    cli()
