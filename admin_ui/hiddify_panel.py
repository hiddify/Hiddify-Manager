#!/usr/bin/env python3

import pathlib



from bottle import  run,static_file,route

import admin_ui
import user_ui
from common import dirname
# @route('/admin/static/<filename:re:.*\.css>')
# @route('/user/static/<filename:re:.*\.css>')
# def send_css(filename):
#     return static_file(filename, root=f'{dirname}/static/asset/css')

# @route('/admin/static/<filename:re:.*\.js>')
# @route('/user/static/<filename:re:.*\.js>')
# def send_js(filename):
#     return static_file(filename, root=f'{dirname}/static/asset/js')

# @route('/admin/static/<filename:re:.*\.(png|jpg|webp)>')
# @route('/user/static/<filename:re:.*\.(png|jpg|webp)>')
# def send_img(filename):
#     return static_file(filename, root=f'{dirname}/static/asset/images')

@route('/admin/static/<filename:re:.*>')
@route('/user/static/<filename:re:.*>')
def send_assets(filename):
    if ".." in filename:return "not found"
    return static_file(filename, root=f'{dirname}/static/asset/')


run(host='localhost', port=439)

