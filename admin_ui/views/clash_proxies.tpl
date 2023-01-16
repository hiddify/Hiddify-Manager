proxies:
% if data["FAKE_CDN_DOMAIN"]!='':
  % if data["ENABLE_VMESS"]=='true':
  - name: FakeCDN vmess_ws proxyproviderip
    type: vmess
    server: {{data["FAKE_CDN_DOMAIN"]}}
    port: 443
    uuid: userguidsecret
    alterId: 0
    cipher: auto
    udp: true
    tls: true
    skip-cert-verify: true
    servername: {{data["FAKE_CDN_DOMAIN"]}}
    network: ws
    ws-opts:
      path: /BASE_PATH/vmessws
      headers:
        Host: proxyproviderip

  - name: FakeCDN vmess_grpc proxyproviderip
    type: vmess
    server: {{data["FAKE_CDN_DOMAIN"]}}
    port: 443
    uuid: userguidsecret
    alterId: 0
    cipher: auto
    udp: true
    tls: true
    skip-cert-verify: true
    servername: proxyproviderip
    network: grpc
    grpc-opts:
      grpc-service-name: BASE_PATH-vmgrpc
  % end

  - name: FakeCDN trojan_ws proxyproviderip
    type: trojan
    password: userguidsecret
    server: {{data["FAKE_CDN_DOMAIN"]}}
    port: 443
    udp: true
    sni: {{data["FAKE_CDN_DOMAIN"]}}
    skip-cert-verify: true
    network: ws
    ws-opts:
      path: /BASE_PATH/trojanws
      headers:
        Host: proxyproviderip

  - name: trojan-grpc proxyproviderip
    type: trojan
    password: userguidsecret
    server: {{data["FAKE_CDN_DOMAIN"]}}
    port: 443
    udp: true
    sni: proxyproviderip
    skip-cert-verify: true
    #alpn:
    #  - h2
    network: grpc
    grpc-opts:
      grpc-service-name: BASE_PATH-trgrpc
  % if data["meta_or_normal"]=='meta':
  - name: FakeCDN vless_ws proxyproviderip
    type: vless
    uuid: userguidsecret
    server: {{data["FAKE_CDN_DOMAIN"]}}
    port: 443
    udp: true
    tls: true
    servername: {{data["FAKE_CDN_DOMAIN"]}}
    skip-cert-verify: true
    network: ws
    ws-opts:
      path: /BASE_PATH/vlessws
      headers:
        Host: proxyproviderip
    

  - name: FakeCDN vless-grpc proxyproviderip
    type: vless
    uuid: userguidsecret
    server: {{data["FAKE_CDN_DOMAIN"]}}
    port: 443
    udp: true
    tls: true
    servername: proxyproviderip
    skip-cert-verify: true
    network: grpc
    grpc-opts:
      grpc-service-name: BASE_PATH-vlgrpc
    % end
% end

% if data["meta_or_normal"]=='meta':
  - name: vless+xtls proxyproviderip
    type: vless
    uuid: userguidsecret
    server: serverip
    port: 443
    udp: true
    tls: false
    servername: proxyproviderip
    skip-cert-verify: true
    flow: xtls-rprx-direct

  - name: vless_ws proxyproviderip
    type: vless
    uuid: userguidsecret
    server: serverip
    port: 443
    udp: true
    tls: true
    servername: proxyproviderip
    skip-cert-verify: true
    network: ws
    ws-opts:
      path: /BASE_PATH/vlessws


  - name: CDN vless_ws proxyproviderip
    type: vless
    uuid: userguidsecret
    server: cloudprovider
    port: 443
    udp: true
    tls: true
    servername: proxyproviderip
    skip-cert-verify: true
    network: ws
    ws-opts:
      path: /BASE_PATH/vlessws


  - name: vless-grpc proxyproviderip
    type: vless
    uuid: userguidsecret
    server: serverip
    port: 443
    udp: true
    tls: true
    servername: proxyproviderip
    skip-cert-verify: true
    network: grpc
    grpc-opts:
      grpc-service-name: BASE_PATH-vlgrpc
  - name: vless+tls proxyproviderip
    type: vless
    uuid: userguidsecret
    server: serverip
    port: 443
    udp: true
    tls: true
    servername: proxyproviderip
    skip-cert-verify: true

  - name: vless+tls+http1.1 proxyproviderip
    type: vless
    uuid: userguidsecret
    server: serverip
    port: 443
    udp: true
    tls: true
    servername: proxyproviderip
    skip-cert-verify: true
% end



% if data["ENABLE_VMESS"]=='true':
  - name: vmess_ws proxyproviderip
    type: vmess
    server: serverip
    port: 443
    uuid: userguidsecret
    alterId: 0
    cipher: auto
    udp: true
    tls: true
    skip-cert-verify: true
    servername: proxyproviderip
    network: ws
    ws-opts:
      path: /BASE_PATH/vmessws

  - name: CDN vmess_ws proxyproviderip
    type: vmess
    server: cloudprovider
    port: 443
    uuid: userguidsecret
    alterId: 0
    cipher: auto
    udp: true
    tls: true
    skip-cert-verify: true
    servername: proxyproviderip
    network: ws
    ws-opts:
      path: /BASE_PATH/vmessws

  - name: vmess_grpc proxyproviderip
    type: vmess
    server: serverip
    port: 443
    uuid: userguidsecret
    alterId: 0
    cipher: auto
    udp: true
    tls: true
    skip-cert-verify: true
    servername: proxyproviderip
    network: grpc
    grpc-opts:
      grpc-service-name: BASE_PATH-vmgrpc

  - name: vmess+tls proxyproviderip
    type: vmess
    server: serverip
    port: 443
    uuid: userguidsecret
    alterId: 0
    cipher: auto
    udp: true
    tls: true
    skip-cert-verify: true
    servername: proxyproviderip
    network: http
    http-opts:
      path:
        - /BASE_PATH/vmtc

  - name: vmess+tls+http1.1 proxyproviderip
    type: vmess
    server: serverip
    port: 443
    uuid: userguidsecret
    alterId: 0
    cipher: auto
    udp: true
    tls: true
    skip-cert-verify: true
    servername: proxyproviderip
    network: http
    http-opts:
      path:
        - /BASE_PATH/vmtc

% if False:
  - name: old_vmess_proxyproviderip_vmess_18831
    type: vmess
    server: serverip
    port: 443
    uuid: userguidsecret
    alterId: 0
    cipher: chacha20-poly1305
    udp: true
    tls: true
    skip-cert-verify: true
    servername: proxyproviderip
    network: ws
    ws-opts:
      path: /BASE_PATH/vmess/
            
  - name: CDN old_vmess_proxyproviderip_vmess_18831
    type: vmess
    server: cloudprovider
    port: 443
    uuid: userguidsecret
    alterId: 0
    cipher: chacha20-poly1305
    udp: true
    tls: true
    skip-cert-verify: true
    servername: proxyproviderip
    network: ws
    ws-opts:
      path: /BASE_PATH/vmess/

% end

% end
  - name: trojan_ws proxyproviderip
    type: trojan
    password: userguidsecret
    server: serverip
    port: 443
    udp: true
    sni: proxyproviderip
    skip-cert-verify: true
#    alpn:
#      - h2
    network: ws
    ws-opts:
      path: /BASE_PATH/trojanws

  - name: CDN trojan_ws proxyproviderip
    type: trojan
    password: userguidsecret
    server: cloudprovider
    port: 443
    udp: true
    sni: proxyproviderip
    skip-cert-verify: true
    # alpn:
    #   - h2
    network: ws
    ws-opts:
      path: /BASE_PATH/trojanws

  - name: trojan-grpc proxyproviderip
    type: trojan
    password: userguidsecret
    server: serverip
    port: 443
    udp: true
    sni: proxyproviderip
    skip-cert-verify: true
    #alpn:
    #  - h2
    network: grpc
    grpc-opts:
      grpc-service-name: BASE_PATH-trgrpc

  - name: trojan+tls proxyproviderip
    type: trojan
    password: userguidsecret
    server: serverip
    port: 443
    udp: true
    sni: proxyproviderip
    skip-cert-verify: true
#    alpn:
#      - h2
  # - name: trojan+tls+http1.1_proxyproviderip_trojan_78009
  #   type: trojan
  #   password: userguidsecret
  #   server: serverip
  #   port: 443
  #   udp: true
  #   sni: proxyproviderip
  #   skip-cert-verify: true
  #   alpn:
  #     - http/1.1

% if data["ENABLE_SS"] == 'true':
  - name: old_ssfaketls proxyproviderip
    type: ss
    cipher: chacha20-ietf-poly1305
    password: %%TELEGRAM_SECRET%%
    server: serverip
    port: 443
    udp_over_tcp: true
    plugin: obfs
    plugin-opts:
      mode: tls
      host: www.google.com
  - name: old_v2ray proxyproviderip
    type: ss
    cipher: chacha20-ietf-poly1305
    password: %%TELEGRAM_SECRET%%
    server: serverip
    port: 443
    udp_over_tcp: true
    plugin: v2ray-plugin
    plugin-opts:
      mode: websocket
      tls: true
      skip-cert-verify: true
      host: proxyproviderip
      path: /BASE_PATH/v2ray/

  - name: CDN old_v2ray proxyproviderip
    type: ss
    cipher: chacha20-ietf-poly1305
    password: %%TELEGRAM_SECRET%%
    server: cloudprovider
    port: 443
    udp_over_tcp: true
    plugin: v2ray-plugin
    plugin-opts:
      mode: websocket
      tls: true
      skip-cert-verify: true
      host: proxyproviderip
      path: /BASE_PATH/v2ray/


% end 

% if False:
  - name: old_trojan-go_proxyproviderip_trojan-go_86355
    type: trojan
    password: 1
    server: serverip
    port: 443
    udp: true
    sni: proxyproviderip
    skip-cert-verify: true
    network: ws
    ws-opts:
      path: /BASE_PATH/trojan/
      

  - name: CDN old_trojan-go_proxyproviderip_trojan-go_86355
    type: trojan
    password: 1
    server: cloudprovider
    port: 443
    udp: true
    sni: proxyproviderip
    skip-cert-verify: true
    network: ws
    ws-opts:
      path: /BASE_PATH/trojan/

% end 



