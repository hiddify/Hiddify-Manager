import yaml
from common import conf_vars
from os import path

# read/write

def read_yaml():
    yaml_path = conf_vars['USERS_YAML_FILE']
    if not path.exists(yaml_path):
        raise Exception(f"{yaml_path} doesn't exist")

    with open(yaml_path,'r') as f:
        data = yaml.safe_load(f)
        # If data is equal to None, the file probably is empty
        if data == None:
            raise Exception(f"Probably {yaml_path} file is empty")
        return data


def write_yaml(data):
    yaml_path = conf_vars['USERS_YAML_FILE']
    if not path.exists(yaml_path):
        raise Exception(f"{yaml_path} doesn't exist")

    with open(yaml_path,'w') as f:
        yaml.safe_dump(data,f)


# user

def add_user(uuid,name,bandwith,expiry_time,usage):
    # make user as dict for adding to the yaml file
    def make_user_as_dict(uuid,name,bandwith,expiry_time,usage):
        return {"uuid":uuid,"name":str(name),"monthly_usage_limit":float(bandwith),"expiry_time":expiry_time,"current_usage":float(usage)}
    
    try:
        data = read_yaml()
        data['users'].append((make_user_as_dict(uuid,name,bandwith,expiry_time,usage)))
        write_yaml(data)
        return True
    except:
        return False

def del_user(uuid):
    try:
        data = read_yaml()
        for index,user in enumerate(data['users']):
            if user['uuid'] == uuid:
                del data['users'][index]
                write_yaml(data)
                return True
        return False
    except:
        return False

# any parameter that is None, we ignore it and don't touch it, so it remains untouched
def modify_user(uuid,name=None,monthly_usage_limit=None,expiry_time=None,current_usage=None):
    if name == None and monthly_usage_limit == None and expiry_time == None and current_usage == None:
        return True
    try:
        data = read_yaml()
        for index,user in enumerate(data['users']):
            if user['uuid'] == uuid:
                if name != None:
                    user['name'] = name
                if monthly_usage_limit != None:
                    user['monthly_usage_limit'] = monthly_usage_limit
                if expiry_time != None:
                    user['expiry_time'] = expiry_time
                if current_usage != None:
                    user['current_usage'] = current_usage
                write_yaml(data)
        return True
    except:
        return False

def list_users():
    data = read_yaml()
    return data['users']



# domain

def add_domain(addr,cdn):
    def make_domain_as_dict(addr,cdn):
        return {addr:{"cdn":cdn}}
    try:
        data = read_yaml()
        data['domains'].append(make_domain_as_dict(addr,cdn))
        write_yaml(data)
        return True
    except:
        return False

def del_domain(addr):
    try:
        data = read_yaml()
        for index,domain_item in enumerate(data['domains']):
            if addr in domain_item:
                del data['domains'][index]
                write_yaml(data)
                return True
    except:
        return False

def modify_domain(addr,cdn):
    try:
        data = read_yaml()
        if addr in data['domains']:
            data['domains'][addr]['cdn'] = cdn
            write_yaml(data)
        return True
    except:
        return False

        
def list_domains():
    data = read_yaml()
    return data['domains']