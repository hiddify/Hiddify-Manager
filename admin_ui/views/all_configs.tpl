% if data["FAKE_CDN_DOMAIN"]!='':
#WS Fake CDN:
vless://userguidsecret@{{data["FAKE_CDN_DOMAIN"]}}:443?security=tls&sni={{data["FAKE_CDN_DOMAIN"]}}&type=ws&host=proxyproviderip&path=%2FBASE_PATH%2Fvlessws#FakeCDNvless_ws_proxyproviderip
trojan://userguidsecret@{{data["FAKE_CDN_DOMAIN"]}}:443?security=tls&sni={{data["FAKE_CDN_DOMAIN"]}}&type=ws&host=proxyproviderip&path=%2FBASE_PATH%2Ftrojanws#FakeCDNtrojan_ws_proxyproviderip
% if data["ENABLE_VMESS"]=='true':
vmess://{"v":"2", "ps":"FakeCDNvmess_ws_proxyproviderip", "add":"cloudprovider", "port":"443", "id":"userguidsecret", "aid":"0", "scy":"auto", "net":"ws", "type":"none", "host":"proxyproviderip", "path":"/BASE_PATH/vmessws", "tls":"tls", "sni":"{{data["FAKE_CDN_DOMAIN"]}}"}
% end

#GRPC Fake CDN
vless://userguidsecret@{{data["FAKE_CDN_DOMAIN"]}}:443?security=tls&sni=proxyproviderip&type=grpc&serviceName=usersecret-vlgrpc&mode=multi#vless-grpc_proxyproviderip
trojan://userguidsecret@{{data["FAKE_CDN_DOMAIN"]}}:443?security=tls&sni=proxyproviderip&type=grpc&serviceName=usersecret-trgrpc&mode=multi#trojan-grpc_proxyproviderip
% if data["ENABLE_VMESS"]=='true':
vmess://{"v":"2", "ps":"vmess_grpc_proxyproviderip", "add":"{{data["FAKE_CDN_DOMAIN"]}}", "port":"443", "id":"userguidsecret", "aid":"0", "scy":"auto", "net":"grpc", "type":"multi", "host":"proxyproviderip", "path":"usersecret-vmgrpc", "tls":"tls", "sni":"{{data["FAKE_CDN_DOMAIN"]}}"}
% end


% end


#xtls:
vless://userguidsecret@serverip:443?flow=xtls-rprx-direct&security=xtls&sni=proxyproviderip&type=tcp#vless+xtls_proxyproviderip

#ws:
vless://userguidsecret@serverip:443?security=tls&sni=proxyproviderip&type=ws&path=%2FBASE_PATH%2Fvlessws#vless_ws_proxyproviderip
trojan://userguidsecret@serverip:443?security=tls&sni=proxyproviderip&type=ws&path=%2FBASE_PATH%2Ftrojanws#trojan_ws_proxyproviderip
% if data["ENABLE_VMESS"]=='true':
vmess://{"v":"2", "ps":"vmess_ws_proxyproviderip", "add":"serverip", "port":"443", "id":"userguidsecret", "aid":"0", "scy":"auto", "net":"ws", "type":"none", "host":"", "path":"/BASE_PATH/vmessws", "tls":"tls", "sni":"proxyproviderip"}
% end

#ws CDN:
vless://userguidsecret@cloudprovider:443?security=tls&sni=proxyproviderip&type=ws&path=%2FBASE_PATH%2Fvlessws#CDNvless_ws_proxyproviderip
trojan://userguidsecret@cloudprovider:443?security=tls&sni=proxyproviderip&type=ws&path=%2FBASE_PATH%2Ftrojanws#CDNtrojan_ws_proxyproviderip


% if data["ENABLE_VMESS"]=='true':
vmess://{"v":"2", "ps":"CDNvmess_ws_proxyproviderip", "add":"cloudprovider", "port":"443", "id":"userguidsecret", "aid":"0", "scy":"auto", "net":"ws", "type":"none", "host":"", "path":"/BASE_PATH/vmessws", "tls":"tls", "sni":"proxyproviderip"}
% end




#grpc
vless://userguidsecret@serverip:443?security=tls&sni=proxyproviderip&type=grpc&serviceName=usersecret-vlgrpc&mode=multi#vless-grpc_proxyproviderip
trojan://userguidsecret@serverip:443?security=tls&sni=proxyproviderip&type=grpc&serviceName=usersecret-trgrpc&mode=multi#trojan-grpc_proxyproviderip
% if data["ENABLE_VMESS"]=='true':
vmess://{"v":"2", "ps":"vmess_grpc_proxyproviderip", "add":"serverip", "port":"443", "id":"userguidsecret", "aid":"0", "scy":"auto", "net":"grpc", "type":"multi", "host":"", "path":"usersecret-vmgrpc", "tls":"tls", "sni":"proxyproviderip"}
% end

#tls
trojan://userguidsecret@serverip:443?security=tls&sni=proxyproviderip&type=tcp#trojan+tls_proxyproviderip
vless://userguidsecret@serverip:443?security=tls&sni=proxyproviderip&type=tcp#vless+tls_proxyproviderip
% if data["ENABLE_VMESS"]=='true':
vmess://{"v": "2", "ps": "vmess+tls_proxyproviderip", "add": "serverip", "port": "443", "id": "userguidsecret", "aid": "0", "scy": "auto", "net": "tcp", "type":"http", "host": "", "path": "/BASE_PATH/vmtc", "tls": "tls", "sni": "proxyproviderip"}
% end


#tls+http2
#trojan://userguidsecret@serverip:443?security=tls&sni=proxyproviderip&alpn=h2&type=tcp&headerType=http&path=%2FBASE_PATH%2Ftrtc#trojan+tls+http1.1_proxyproviderip
vless://userguidsecret@serverip:443?security=tls&sni=proxyproviderip&alpn=h2&type=tcp&headerType=http&path=%2FBASE_PATH%2Fvltc#vless+tls+http1.1_proxyproviderip
% if data["ENABLE_VMESS"]=='true':
vmess://{"v": "2", "ps": "vmess+tls+http1.1_proxyproviderip", "add": "serverip", "port": "443", "id": "userguidsecret", "aid": "0", "scy": "auto", "net": "tcp", "type": "http", "host": "", "path": "/BASE_PATH/vmtc", "tls": "tls", "sni": "proxyproviderip", "alpn": "h2"}
% end





% if data["ENABLE_SS"] == 'true':
#old
ss://chacha20-ietf-poly1305:usersecret@serverip:443?plugin=v2ray-plugin%3Bmode%3Dwebsocket%3Bpath%3D%2FBASE_PATH%2Fv2ray%2F%3Bhost%3Dproxyproviderip%3Btls&amp;udp-over-tcp=true#old_v2ray_proxyproviderip
ss://chacha20-ietf-poly1305:usersecret@serverip:443?plugin=obfs-local%3Bobfs%3Dtls%3Bobfs-host%3Dwww.google.com&amp;udp-over-tcp=true#old_ssfaketls_proxyproviderip
% end
% if False:
# trojan-go://1@proxyproviderip:443?host=proxyproviderip&path=/BASE_PATH/trojan/&type=ws#old_trojan-go_proxyproviderip
#  vmess://{&quot;add&quot;:&quot;proxyproviderip&quot;,&quot;aid&quot;:&quot;0&quot;,&quot;host&quot;:&quot;cloudprovider&quot;,&quot;id&quot;:&quot;userguidsecret&quot;,&quot;net&quot;:&quot;ws&quot;,&quot;path&quot;:&quot;/BASE_PATH/vmess/&quot;,&quot;port&quot;:&quot;443&quot;,&quot;ps&quot;:&quot;old_vmess_proxyproviderip&quot;,&quot;scy&quot;:&quot;chacha20-poly1305&quot;,&quot;sni&quot;:&quot;proxyproviderip&quot;,&quot;tls&quot;:&quot;tls&quot;,&quot;type&quot;:&quot;&quot;,&quot;v&quot;:&quot;2&quot;}
% end