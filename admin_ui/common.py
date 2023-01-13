import pathlib
import yaml


config_dir=pathlib.Path(__file__).parent.parent.resolve()
dirname = pathlib.Path(__file__).parent.resolve()
conf_vars={
        "MAIN_DOMAIN":"domain", 
        "NO_CDN_DOMAIN":"domain", 
        "USER_SECRET":"uuid",
        "ADMIN_SECRET":"uuid",
        "CDN_NAME":"string",
        "TELEGRAM_FAKE_TLS_DOMAIN":"domain",
        "SS_FAKE_TLS_DOMAIN":"domain",
        "ENABLE_FIREWALL":"boolean",
        "ENABLE_NETDATA":"boolean",
        "ALLOW_ALL_SNI_TO_USE_PROXY":"boolean",
        "ENABLE_HTTP_PROXY":"boolean",
        "ENABLE_AUTO_UPDATE":"boolean",
        "BLOCK_IR_SITES":"boolean",
        "USERS_YAML_FILE": "/home/me/code/github/hiddify/org-repo/hiddify-config/hiddify-config/admin_ui/users.yml"
}

def read_configs(read_default=True):
    out=read_config_from_file(f'{config_dir}/config.env.default') if read_default else {}
    return {**out,**read_config_from_file(f'{config_dir}/config.env')}

def read_config_from_file(f):
    out={}
    with open(f,'r') as f:
        for line in f:
            line=line.strip()
            if line.startswith("#"):
                continue
            if line=="":
                continue
            line=line.split("#")[0]
            splt=line.split("=")
            out[splt[0].strip()]=splt[1].strip()
    return out

def set_configs(configs):
    configs={key:val for key,val in configs.items() if val is not None}
    new_configs={**read_configs(read_default=False),**configs}
    
    all_lines=""
    
    
    for key,val in new_configs.items():
        all_lines+=f"{key}={val}\n"

    with open(f'{config_dir}/config.env','w') as f:
        f.write(all_lines)

# make user as dict for adding to the yaml file
def make_user(uuid,name,bandwith,expire_time,usage):
    return {uuid:{"name":str(name),"bandwith":float(bandwith),"expire_time":expire_time,"usage":float(usage)}}

def add_user_to_yaml_file(uuid,name,bandwith,expire_time,usage):
    data = read_yaml(conf_vars['USERS_YAML_FILE'])
    data['Users'].update(make_user(uuid,name,bandwith,expire_time,usage))

    write_yaml(conf_vars['USERS_YAML_FILE'],data)

def read_yaml(path):
    with open(path,'r') as f:
        return yaml.safe_load(f)

def write_yaml(path,data):
    with open(path,'w') as f:
        yaml.safe_dump(data,f)

