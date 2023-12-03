import click
import validators
import os
from strenum import StrEnum
import subprocess
import shlex

HIDDIFY_DIR = '/opt/hiddify-manager/'

class Command(StrEnum):
    '''The value of each command refers to the command shell file'''
    apply = os.path.join(HIDDIFY_DIR,'apply.sh')
    install = os.path.join(HIDDIFY_DIR,'install.sh')
    reinstall = os.path.join(HIDDIFY_DIR,'reinstall.sh')
    update = os.path.join(HIDDIFY_DIR,'update.sh')
    status = os.path.join(HIDDIFY_DIR,'status.sh')
    restart_services = os.path.join(HIDDIFY_DIR,'restart.sh')
    add_temporary_short_link = os.path.join(HIDDIFY_DIR,'nginx/add2shortlink.sh')

def escape_os_injection(input_string:str):
    # Define a dictionary mapping special characters to their escaped versions
    escape_chars = {
        '&': '\\&',
        ';': '\\;',
        '|': '\\|',
        '`': '\\`',
        '$': '\\$',
        '(': '\\(',
        ')': '\\)',
        '<': '\\<',
        '>': '\\>',
        '!': '\\!',
        '*': '\\*',
        '?': '\\?',
        '[': '\\[',
        ']': '\\]',
        '{': '\\{',
        '}': '\\}',
        '\'': '\\\'',
        '\"': '\\\"',
        '\\': '\\\\'
    }
    
    # Replace each special character in the input string with its escaped version
    for char, escaped_char in escape_chars.items():
        input_string = input_string.replace(char, escaped_char)
    
    return shlex.quote(input_string)

def run_command(command:Command, **kwargs:str|int) -> subprocess.CalledProcessError | None:
    """
    Runs a command and returns None if the command ended successfully,
    otherwise returns a CalledProcessError.

    Args:
        command (str): The command to be executed.
        **kwargs: Additional keyword arguments that may be required for specific commands.

    Returns:
        Union[subprocess.CalledProcessError, None]: None if the command ended successfully,
            otherwise a CalledProcessError indicating the error.

    Raises:
        Exception: If invalid inputs are passed for the 'add_temporary_short_link' command.
    """
    def run(cmd:list[str]):
        try:
            subprocess.run(cmd,shell=False,check=True)
        except Exception as e:
            raise e
        
    match command:
        case command.apply:
            cmd = [command.value]
            run(cmd)
        case command.install:
            cmd = [command.value]
            run(cmd)
        case command.reinstall:
            cmd = [command.value]
            run(cmd)
        case command.update:
            cmd = [command.value]
            run(cmd)
        case command.status:
            cmd = [command.value]
            run(cmd)
        case command.restart_services:
            cmd = [command.value]
            run(cmd)
        case command.add_temporary_short_link:
            if 'url' not in kwargs or 'slug' not in kwargs:
                raise Exception('Invalid inputs passed for add_temporary_short_link command')
            
            sanitized_url = escape_os_injection(kwargs['url']) # type: ignore
            # don't need to sanitize slug but we do for good (we are not lucky)
            sanitized_slug = escape_os_injection(kwargs['slug']) # type: ignore

            cmd = [command.value,'--url',sanitized_url,'--slug',sanitized_slug]

            run(cmd)
                
            

@click.group(chain=True)
def cli():
    pass

@cli.command('apply')
def apply():
    run_command(Command.apply)

@cli.command('install')
def install():
    run_command(Command.install)


@cli.command('reinstall')
def reinstall():
    run_command(Command.reinstall)


@cli.command('update')
def update():
    run_command(Command.update)




@cli.command('restart-services')
def restart_services():
    run_command(Command.restart_services)



@cli.command('status')
#@click.option('--status')
def status():
    run_command(Command.status)
    print('executing status.sh')



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

@cli.command('add-temporary-short-link')
@click.option('--url','-u',type=str,help='The url that is going to be short',required=True)
@click.option('--slug','-s',type=str,help='The secret code',required=True)
@click.option('--period','-p',type=int,help='The time period that link remains active',required=False)
def add_temporary_short_link(url:str,slug:str,period:int):
    # validate inputs
    error = add_temporary_short_link_input_error(url,slug,period)
    if error is not None:
        print(error)
        exit(1)

    print('executing add-temporary-short-link.sh')
    run_command(Command.add_temporary_short_link,url=url,slug=slug,period=period)


if __name__ == "__main__":
    cli()