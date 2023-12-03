import click
import validators

@click.group(chain=True)
def cli():
    pass

@cli.command('apply')
#@click.option('--apply')
def apply():
    print('executing apply.sh')

@cli.command('install')
def install():
    print('executing install.sh')


@cli.command('reinstall')
def reinstall():
    print('executing reinstall.sh')


@cli.command('update')
def update():
    print('executing update.sh')




@cli.command('restart-services')
def restart_services():
    print('executing restart-services.sh')



@cli.command('status')
#@click.option('--status')
def status():
    print('executing status.sh')

def add_temporary_short_link_input_error(url:str,slug:str,period:int) -> Exception | None:
    '''Returns None if everything is valid otherwise returns an error'''
    
    def is_url_valid(url:str):
        if validators.url(url) == True:
            return True
        return False
    
    # check url validity
    if not url:
        return Exception(f"Error: Invalid value for '--url' / '-u': \"\" is not a valid url")
    if not is_url_valid(url):
        return Exception(f"Error: Invalid value for '--url' / '-u': {url} is an invalid url")

    # check slug
    if not slug:
        return Exception(f"Error: Invalid value for '-slug' / '-s': \"\" is not a valid slug")
    if not slug.isalnum():
        return Exception(f"Error: Invalid value for '-slug' / '-s': \"\" is not a alphanumeric")
    
    return None

@cli.command('add-temporary-short-link')
@click.option('--url','-u',type=str,help='The url that is going to be short',required=True)
@click.option('--slug','-s',type=str,help='The secret code',required=True)
@click.option('--period','-p',type=int,help='The time period that link remains active',required=False)
#@click.option('--add-temporary-short-link')
def add_temporary_short_link(url:str,slug:str,period:int):
    # validate inputs
    error = add_temporary_short_link_input_error(url,slug,period)
    if error is not None:
        print(error)
        exit(1)

    print('executing add-temporary-short-link.sh')
    

def main():
    cli()


if __name__ == "__main__":
    main()