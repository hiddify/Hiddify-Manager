mixed-port: 7890
allow-lan: false
log-level: info
secret: 
external-controller: 127.0.0.1:9090
ipv6: false
mode: rule
dns:
  enable: true
  use-hosts: true
  ipv6: false
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  listen: 127.0.0.1:6868
  fake-ip-filter:
     - 'proxyproviderip'
     - '{{data["TELEGRAM_FAKE_TLS_DOMAIN"]}}'
  default-nameserver:
% if data["meta_or_normal"]=='meta':
    - https://1.1.1.1/dns-query#PROXY
    - https://8.8.8.8/dns-query#PROXY
    - https://1.0.0.1/dns-query#PROXY
% end
    - 1.1.1.1
    - 8.8.8.8
    - 1.0.0.1
  nameserver:
#    - https://proxyproviderip/BASE_PATH/dns/dns-query
% if data["meta_or_normal"]=='meta':
    - https://1.1.1.1/dns-query#PROXY
    - https://8.8.8.8/dns-query#PROXY
    - https://1.0.0.1/dns-query#PROXY
% end
    - 8.8.8.8
    - 1.1.1.1

proxy-groups:
  - name: auto_all
    use:
      - all_proxies
    type: url-test
    url: http://cp.cloudflare.com
    interval: 300

  - name: auto
    type: fallback
    url: 'http://cp.cloudflare.com'
    interval: 300
    proxies:
        - auto_all
        - OnProxyIssue

  - name: PROXY
    proxies:
      - auto
    use:
      - all_proxies
    type: select


  - name: OnIranSites
    proxies:
    % if data["mode"]=="all":
      - PROXY
      - DIRECT
    % else:
      - DIRECT
      - PROXY
    % end
    type: select

  - name: OnNotFilteredSites
    proxies:
    % if data["mode"]=="lite":
      - DIRECT
      - PROXY
    % else:
      - PROXY
      - DIRECT
    % end
    type: select  

  - name: OnProxyIssue
    proxies:
    % if data["mode"]=="all":
      - REJECT
      - DIRECT
    % else:
      - DIRECT
      - REJECT
    % end
    type: select

proxy-providers:
  all_proxies:
    type: http
    url: "https://proxyproviderip/{{data["BASE_PROXY_PATH"]}}/{{data["user_id"]}}/clash/{{data["meta_or_normal"]}}/proxies.yml?{{hash(f'{data}')}}"
    path: proxyproviderip/{{data["user_id"]}}-{{data["meta_or_normal"]}}-proxies{{hash(f'{data}')}}.yaml
    health-check:
      enable: true
      interval: 600
      url: http://www.gstatic.com/generate_204    

  
rule-providers:

  blocked:
    type: http
    behavior: classical
    url: "https://proxyproviderip/BASE_PATH/clash/rules/blocked-sites.yml"
    path: ./ruleset/blocked.yaml
    interval: 432000

  tmpblocked:
    type: http
    behavior: classical
    url: "https://proxyproviderip/BASE_PATH/clash/rules/tmp-blocked-sites.yml"
    path: ./ruleset/tmpblocked.yaml
    interval: 432000

  open:
    type: http
    behavior: classical
    url: "https://proxyproviderip/BASE_PATH/clash/rules/open-sites.yml"
    path: ./ruleset/open.yaml
    interval: 432000    

  ads:
    type: http
    behavior: classical
    url: "https://proxyproviderip/BASE_PATH/clash/rules/ads-sites.yml"
    path: ./ruleset/ads.yaml
    interval: 432000   

rules:
  - DOMAIN,{{data["TELEGRAM_FAKE_TLS_DOMAIN"]}},DIRECT
  - DOMAIN,proxyproviderip,DIRECT
  - IP-CIDR,{{data["external_ip"]}}/32,DIRECT
  - IP-CIDR,10.10.34.0/24,PROXY
  - RULE-SET,tmpblocked,PROXY
  - RULE-SET,blocked,PROXY
  - GEOIP,IR,OnIranSites
  - DOMAIN-SUFFIX,.ir,OnIranSites
  - RULE-SET,open,OnIranSites
  - RULE-SET,ads,REJECT
  - MATCH,OnNotFilteredSites
