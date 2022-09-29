from http.server import HTTPServer, BaseHTTPRequestHandler
import ssl

import urllib.request

external_ip = urllib.request.urlopen('https://ident.me').read().decode('utf8')

print(external_ip)
usersecret='751F2F753854422EA4C5FDDB8314F068'
class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        if self.path==f'/{usersecret}':
                clash = urllib.request.urlopen('https://raw.githubusercontent.com/hiddify/config/main/clash.yml').read().decode('utf8')
                clash=clash.replace('serverip', external_ip)
                clash=clash.replace('usersecret', usersecret)
                clash=bytes(clash,'utf-8')
                self.wfile.write(clash)


httpd = HTTPServer(('0.0.0.0', 80), SimpleHTTPRequestHandler)

httpd.socket = ssl.wrap_socket (httpd.socket,
        keyfile="key.pem",
        certfile='cert.pem', server_side=True)

httpd.serve_forever()
