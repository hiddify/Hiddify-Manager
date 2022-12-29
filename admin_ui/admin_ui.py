#!/usr/bin/env python3

import pathlib



from bottle import route, run, template,redirect,request,static_file
from datetime import datetime,timedelta,date
import os,sys
import json
import urllib.request
import subprocess
import re
config_dir=pathlib.Path(__file__).parent.parent.resolve()
dirname = pathlib.Path(__file__).parent.resolve()
conf_vars=[
        "MAIN_DOMAIN", 
        "USER_SECRET",
        "ADMIN_SECRET",
        "CDN_NAME",
        "TELEGRAM_FAKE_TLS_DOMAIN",
        "SS_FAKE_TLS_DOMAIN",
        "ENABLE_FIREWALL",
        "ENABLE_AUTO_UPDATE"
    ]
@route('/')
def index():
    return template('index')

@route('/config/')
def redirect_no_tailing_slash():
    newu=request.url.split('/')[-2]
    return f"<html><head><meta http-equiv='refresh' content='0;url=../{newu}' /></head><body>this page is moved to <a href='../{newu}'>../{newu}</a></body></html>"

@route('/config')
def config():
    configs=read_configs()
    data={name:configs.get(name,"") for name in conf_vars}
    
    data["external_ip"]= urllib.request.urlopen('https://v4.ident.me/').read().decode('utf8')

    

    return template("config",data=data)

@route('/change')
def change():
    new_configs={}
    domain_fields=["MAIN_DOMAIN","TELEGRAM_FAKE_TLS_DOMAIN","SS_FAKE_TLS_DOMAIN"]
    secret_fields=["USER_SECRET","ADMIN_SECRET"]
    boolean_fields=["ENABLE_FIREWALL","ENABLE_AUTO_UPDATE"]
    for domain in domain_fields:
        if not re.search(r'^([A-Za-z0-9\-\.]+\.[a-zA-Z]{2,})$', request.query[domain]):
            return template("result",data={
                        "out-type":"danger",
                        "out-msg":f"Invalid ${domain}=${request.query[domain]}. Click back and fix it"
                    })
        new_configs[domain]=request.query[domain]
    for domain1 in domain_fields:
        for domain2 in domain_fields:
            if domain1!=domain2 and request.query[domain1]==request.query[domain2]:
                return template("result",data={
                        "out-type":"danger",
                        "out-msg":f"Invalid ${domain1}=${request.query[domain1]} and ${domain2}=${request.query[domain2]}. These values should be different."
                    })

    for secret in secret_fields:
        if not re.search(r"^([0-9A-Fa-f]{32})$", request.query[secret]):
            return template("result",data={
                        "out-type":"danger",
                        "out-msg":f"Secret for ${secret}=${request.query[secret]} is incorrect. It should be 32 char hex values. Click back and fix it"
                    })
        new_configs[secret]=request.query[secret]
        
                        
    for bf in boolean_fields:
        new_configs[bf]=request.query.get(bf,'false')!='false'

    for name in conf_vars:
        if name not in new_configs:
            new_configs[name]=request.query.get(name,"")
    
    set_configs(new_configs)
    
    cwd = os.getcwd()
    
    my_env = os.environ.copy()
    for name in new_configs:
        if name in my_env:
            del my_env[name]
    my_env["DO_NOT_INSTALL"]=true
    os.chdir(config_dir)
    # rc = subprocess.call(f"./install.sh &",shell=True)
    subprocess.Popen(f"./install.sh &",env=my_env)
    return template("result",data={
                        "out-type":"Success",
                        "out-msg":("Success! Please wait around 2 minutes to make sure everything is working. Then, please save your Proxy Link which is <br>",
                                f"<h1>User Link</h1><a href='https://{request.query['MAIN_DOMAIN']}/{request.query['USER_SECRET']}/'>https://{request.query['MAIN_DOMAIN']}/{request.query['USER_SECRET']}/</a><br>",
                                f"<h1>Admin Link</h1><a href='https://{request.query['MAIN_DOMAIN']}/{request.query['ADMIN_SECRET']}/'>https://{request.query['MAIN_DOMAIN']}/{request.query['ADMIN_SECRET']}/</a>")
    })


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


@route('/static/<filename:re:.*\.css>')
def send_css(filename):
    return static_file(filename, root=f'{dirname}/static/asset/css')

@route('/static/<filename:re:.*\.js>')
def send_js(filename):
    return static_file(filename, root=f'{dirname}/static/asset/js')

@route('/static/<filename:re:.*\.(png|jpg|webp)>')
def send_img(filename):
    return static_file(filename, root=f'{dirname}/static/asset/images')

run(host='localhost', port=439)