#!/usr/bin/env python3

import pathlib



from bottle import route, run, template,redirect,request,response,static_file
from datetime import datetime,timedelta,date
import os,sys
import json
import urllib.request
import subprocess
import re

from common import read_configs,set_configs,conf_vars,config_dir
@route('/admin/')
def index():
    data=read_configs()
    return template('index',data=data)


@route('/admin/reverselog/<logfile>')
def reverselog(logfile):
    with open(f'{config_dir}/log/system/{logfile}') as f:
        lines=[line for line in f]
        response.content_type = 'text/plain';
        return "".join(lines[::-1])

@route('/admin/apply_configs')
def apply_configs():
    return reinstall(False)

@route('/admin/reinstall')
def reinstall(complete_install=True):
    configs=read_configs()

    file="install.sh" if complete_install else "apply_configs.sh"
    try:
        server_ip=urllib.request.urlopen('https://v4.ident.me/').read().decode('utf8')
    except:
        server_ip="server_ip"
    # subprocess.Popen(f"{config_dir}/update.sh",env=my_env,cwd=f"{config_dir}")
    # os.system(f'cd {config_dir};{env} ./install.sh &')
    # rc = subprocess.call(f"cd {config_dir};./{file} & disown",shell=True)
    subprocess.Popen(f"{config_dir}/{file}",cwd=f"{config_dir}",start_new_session=True)
    
    return template("result",data={
                        "out-type":"success",
                        "out-msg":f"Success! Please wait around {6 if complete_install else 2} minutes to make sure everything is updated. Then, please save your proxy links which are <br>"+
                                # f"<h1>User Link</h1><a href='https://{configs['MAIN_DOMAIN']}/{configs['USER_SECRET']}/'>https://{configs['MAIN_DOMAIN']}/{configs['USER_SECRET']}/</a><br>"+
                                f"<h1>Secure Admin Link</h1><a href='https://{configs['MAIN_DOMAIN']}/{configs['ADMIN_SECRET']}/'>https://{configs['MAIN_DOMAIN']}/{configs['ADMIN_SECRET']}/</a><br>"+
                                f"<h6>Alternative Admin Link1:</h6><a href='https://{server_ip}.sslip.io/{configs['ADMIN_SECRET']}/'>https://{server_ip}.sslip.io/{configs['ADMIN_SECRET']}/</a><br>"+
                                f"<a href='http://{server_ip}/{configs['ADMIN_SECRET']}/'>http://{server_ip}/{configs['ADMIN_SECRET']}/</a><br>",
                        "log-path":f"https://{configs['MAIN_DOMAIN']}/{configs['ADMIN_SECRET']}/reverselog/0-install.log"
                        
    })


@route('/admin/status')
def status():
    configs=read_configs()
    # subprocess.Popen(f"{config_dir}/update.sh",env=my_env,cwd=f"{config_dir}")
    # os.system(f'cd {config_dir};{env} ./install.sh &')
    # rc = subprocess.call(f"cd {config_dir};./{file} & disown",shell=True)
    subprocess.Popen(f"{config_dir}/status.sh",cwd=f"{config_dir}",start_new_session=True)
    return template("result",data={
                        "out-type":"success",
                        "out-msg":f"see the log in the bellow screen",
                        "log-path":f"https://{configs['MAIN_DOMAIN']}/{configs['ADMIN_SECRET']}/reverselog/status.log"
    })


@route('/admin/update')
def update():
    configs=read_configs()
    cwd = os.getcwd()
    
    my_env = os.environ
    for name in configs:
        if name in os.environ:
            del os.environ[name]
    # os.chdir(config_dir)
    # rc = subprocess.call(f"./install.sh &",shell=True)
    # rc = subprocess.call(f"cd {config_dir};./update.sh & disown",shell=True)
    # os.system(f'cd {config_dir};./update.sh &')

    subprocess.Popen(f"{config_dir}/update.sh",cwd=f"{config_dir}",start_new_session=True)
    return template("result",data={
                        "out-type":"success",
                        "out-msg":"Success! Please wait around 5 minutes to make sure everything is updated.<br>",
                        "log-path":"reverselog/update.log"
    })

    


@route('/admin/config/')
def redirect_no_tailing_slash():
    newu=request.url.split('/')[-2]
    return f"<html><head><meta http-equiv='refresh' content='0;url=../{newu}' /></head><body>this page is moved to <a href='../{newu}'>../{newu}</a></body></html>"

@route('/admin/config')
def config():
    configs=read_configs()
    data={name:configs.get(name,"") for name in conf_vars}
    
    data["external_ip"]= urllib.request.urlopen('https://v4.ident.me/').read().decode('utf8')

    

    return template("config",data=data)

@route('/admin/change')
def change():
    new_configs={}
    domain_fields=[c for c in conf_vars if conf_vars[c]=="domain"]
    secret_fields=[c for c in conf_vars if conf_vars[c]=="uuid"]
    boolean_fields=[c for c in conf_vars if conf_vars[c]=="boolean"]
    for domain in domain_fields:
        is_no_cdn=domain=="FAKE_CDN_DOMAIN" and request.query[domain]==""
        if not is_no_cdn and not re.search(r'^([A-Za-z0-9\-\.]+\.[a-zA-Z]{2,})$', request.query[domain]):
            return template("result",data={
                        "out-type":"danger",
                        "out-msg":f"Invalid {domain}={request.query[domain]}. Click back and fix it"
                    })
        new_configs[domain]=request.query[domain].lower()

    for domain1 in domain_fields:
        for domain2 in domain_fields:
            if domain1!=domain2 and new_configs[domain1]==new_configs[domain2]:
                return template("result",data={
                        "out-type":"danger",
                        "out-msg":f"Invalid {domain1}={new_configs[domain1]} and {domain2}={new_configs[domain2]}. These values should be different."
                    })

    for secret in secret_fields:
        if not re.search(r"^([0-9A-Fa-f]{32})$", request.query[secret]):
            return template("result",data={
                        "out-type":"danger",
                        "out-msg":f"Secret for {secret}={request.query[secret]} is incorrect. It should be 32 char hex values. Click back and fix it"
                    })
        new_configs[secret]=request.query[secret]
        
                        
    for bf in boolean_fields:
        new_configs[bf]="true" if request.query.get(bf,'false')!='false' else "false"

    for name in conf_vars:
        if name not in new_configs:
            new_configs[name]=request.query.get(name,"")
    
    set_configs(new_configs)
    
    return apply_configs()
    






