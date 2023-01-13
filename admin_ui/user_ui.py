#!/usr/bin/env python3

import pathlib



from bottle import route, run, template,redirect,request,response,static_file
from datetime import datetime,timedelta,date
import os,sys
import json
import urllib.request
import subprocess
import re
import uuid
from common import read_configs

def read_user_configs(secret):
    data=read_configs()
    data["user_id"]=secret
    data["user_guid"]=f"{uuid.UUID(secret)}"
    return data

@route('/user/<secret>')
def index(secret):
    return template('user',data=read_user_configs(secret))



@route('/user/<secret>/clash/<meta_or_normal>/proxies.yml')
def clash_proxies(secret,meta_or_normal):
    data=read_user_configs(secret)
    data['meta_or_normal']=meta_or_normal
    response.content_type = 'text/plain';
    return template('clash_proxies',data=data)


@route('/user/<secret>/clash/<meta_or_normal>/<mode>.yml')
def clash_config(secret,meta_or_normal,mode):
    data=read_user_configs(secret)
    response.content_type = 'text/plain';
    data['meta_or_normal']=meta_or_normal
    data['mode']=mode
    return template('clash_config',data=data)