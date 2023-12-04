#!/usr/bin/env python
import click
import validators
import os
from strenum import StrEnum
import subprocess
import shlex
import re

HIDDIFY_DIR = '/opt/hiddify-manager/'


class Command(StrEnum):
    '''The value of each command refers to the command shell file'''
    apply = os.path.join(HIDDIFY_DIR, 'apply_configs.sh')
    install = os.path.join(HIDDIFY_DIR, 'install.sh')
    # reinstall = os.path.join(HIDDIFY_DIR,'reinstall.sh')
    update = os.path.join(HIDDIFY_DIR, 'update.sh')
    status = os.path.join(HIDDIFY_DIR, 'status.sh')
    restart_services = os.path.join(HIDDIFY_DIR, 'restart.sh')
    temporary_short_link = os.path.join(HIDDIFY_DIR, 'nginx/add2shortlink.sh')
    temporary_access = os.path.join(
        HIDDIFY_DIR, 'hiddify-panel/temporary_access.sh')


def is_valid_string(input_string):
    escape_chars = set('&;|`$()<>!*?[]{}\\\'"\'"')
    pattern = f"[^{re.escape(''.join(escape_chars))}]"
    return not bool(re.match(pattern, input_string))


def run(cmd: list[str]):
    subprocess.run(cmd, shell=False, check=True)


@click.group(chain=True)
def cli():
    pass


@cli.command('apply')
def apply():
    cmd = [Command.apply.value]
    run(cmd)


@cli.command('install')
def install():
    cmd = [Command.install.value]
    run(cmd)


# @cli.command('reinstall')
# def reinstall():
#     cmd = [Command.reinstall.value]
#     run(cmd)


@cli.command('update')
def update():
    cmd = [Command.update.value]
    run(cmd)


@cli.command('restart-services')
def restart_services():
    cmd = [Command.restart_services.value]
    run(cmd)


@cli.command('status')
def status():
    cmd = [Command.status.value]
    run(cmd)


def add_temporary_short_link_input_error(url: str, slug: str, period: int) -> Exception | None:
    '''Returns None if everything is valid otherwise returns an error'''

    if not url:
        return Exception(f"Error: Invalid value for '--url' / '-u': \"\" is not a valid url")

    if not validators.url(url):
        return Exception(f"Error: Invalid value for '--url' / '-u': {url} is an invalid url")

    if not slug:
        return Exception(f"Error: Invalid value for '-slug' / '-s': \"\" is not a valid slug")

    if not slug.isalnum():
        return Exception(f"Error: Invalid value for '-slug' / '-s': \"\" is not a alphanumeric")

    return None


@cli.command('temporary-short-link')
@click.option('--url', '-u', type=str, help='The url that is going to be short', required=True)
@click.option('--slug', '-s', type=str, help='The secret code', required=True)
@click.option('--period', '-p', type=int, help='The time period that link remains active', required=False)
def add_temporary_short_link(url: str, slug: str, period: int):
    # validate inputs
    error = add_temporary_short_link_input_error(url, slug, period)
    if error is not None:
        print(error)
        exit(1)

    if not url or not slug:
        print('Error: Invalid inputs passed for add_temporary_short_link command')
        exit(1)

    is_url_valid = is_input_valid(url)  # type: ignore
    if not is_url_valid:
        raise Exception(f"Error: Invalid character in url: {url}")
    # don't need to sanitize slug but we do for good (we are not lucky)
    is_slug_valid = is_input_valid(slug)  # type: ignore
    if is_slug_valid:
        raise Exception(f"Error: Invalid character in slug: {slug}")

    cmd = [Command.temporary_short_link, url, slug, str(period)]

    run(cmd)


@cli.command('temporary-access')
@click.option('--port', '-p', type=int, help='The port that is going to be open', required=True)
def add_temporary_access(port: int):
    cmd = [Command.temporary_access, str(port)]
    run(cmd)


if __name__ == "__main__":
    cli()
