proxies:
% if data["meta_or_normal"]=='meta':
  - name: vless+xtls_proxyproviderip_vless_98915
    type: vless
    uuid: userguidsecret
    server: serverip
    port: 443
    udp: true
    tls: false
    servername: proxyproviderip
    skip-cert-verify: true
    flow: xtls-rprx-direct

  - name: vless_ws_proxyproviderip_vless_41935
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


  - name: CDN vless_ws_proxyproviderip_vless_41935
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


  - name: vless-grpc_proxyproviderip_vless_61006
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
  - name: vless+tls_proxyproviderip_vless_81611
    type: vless
    uuid: userguidsecret
    server: serverip
    port: 443
    udp: true
    tls: true
    servername: proxyproviderip
    skip-cert-verify: true

  - name: vless+tls+http1.1_proxyproviderip_vless_16517
    type: vless
    uuid: userguidsecret
    server: serverip
    port: 443
    udp: true
    tls: true
    servername: proxyproviderip
    skip-cert-verify: true
% end

  - name: trojan_ws_proxyproviderip_trojan_74488
    type: trojan
    password: userguidsecret
    server: serverip
    port: 443
    udp: true
    sni: proxyproviderip
    skip-cert-verify: true
    alpn:
      - h2
    network: ws
    ws-opts:
      path: /BASE_PATH/trojanws

  - name: vmess_ws_proxyproviderip_vmess_59999
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
  - name: CDN trojan_ws_proxyproviderip_trojan_74488
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

  - name: CDN vmess_ws_proxyproviderip_vmess_59999
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
  - name: trojan-grpc_proxyproviderip_trojan_49303
    type: trojan
    password: userguidsecret
    server: serverip
    port: 443
    udp: true
    sni: proxyproviderip
    skip-cert-verify: true
    alpn:
      - h2
    network: grpc
    grpc-opts:
      grpc-service-name: BASE_PATH-trgrpc
  - name: vmess_grpc_proxyproviderip_vmess_59432
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
  - name: trojan+tls_proxyproviderip_trojan_58054
    type: trojan
    password: userguidsecret
    server: serverip
    port: 443
    udp: true
    sni: proxyproviderip
    skip-cert-verify: true
    alpn:
      - h2
  - name: vmess+tls_proxyproviderip_vmess_93601
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
  - name: vmess+tls+http1.1_proxyproviderip_vmess_11423
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



  - name: old_ssfaketls_proxyproviderip_ss_85981
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
  - name: old_v2ray_proxyproviderip_ss_94133
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
  - name: CDN old_v2ray_proxyproviderip_ss_94133
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





