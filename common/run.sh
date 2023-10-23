source /opt/hiddify-manager/common/utils.sh
function add2iptables() {
  iptables -C $1 || echo "adding rule $1" && iptables -I $1
}

function add2ip6tables() {
  ip6tables -C $1 || echo "adding rule $1" && ip6tables -I $1
}
function allow_port() { #allow_port "tcp" "80"
  add2iptables "INPUT -p $1 --dport $2 -j ACCEPT"
  add2ip6tables "INPUT -p $1 --dport $2 -j ACCEPT"
  # if [[ $1 == 'udp' ]]; then
  add2iptables "INPUT -p $1 -m $1 --dport $2 -m conntrack --ctstate NEW -j ACCEPT"
  add2ip6tables "INPUT -p $1 -m $1 --dport $2 -m conntrack --ctstate NEW -j ACCEPT"
  # fi
}

function block_port() { #allow_port "tcp" "80"
  add2iptables "INPUT -p $1 --dport $2 -j DROP"
  add2ip6tables "INPUT -p $1 --dport $2 -j DROP"
}

function remove_port() { #allow_port "tcp" "80"
  iptables -D INPUT -p $1 --dport $2
  ip6tables -D INPUT -p $1 --dport $2
}

function allow_apps_ports() {
  service_name=$1
  ports=$(ss -tulpn | grep "$service_name" | awk '{print $5}' | cut -d':' -f2)

  if [[ -z $ports ]]; then
    echo "Service not found or not running"
  else
    path=$(ps -aux | grep $service_name | awk '{print $11}')

    IFS=' ' read -ra portArray <<<"$ports"
    for p in "${portArray[@]}"; do
      echo "Service is running on port $p and path $path"
      allow_port "tcp" $p
    done
  fi
}

mkdir -p /etc/iptables/

allow_port "tcp" 22
allow_port "tcp" 80
allow_port "tcp" 443
allow_port "udp" 443
allow_port "udp" 53
allow_port "tcp" 53
# allow_port "udp" 3478

add2iptables "OUTPUT -p udp -j ACCEPT"
add2ip6tables "OUTPUT -p udp -j ACCEPT"

add2iptables "OUTPUT -p tcp -j ACCEPT"
add2ip6tables "OUTPUT -p tcp -j ACCEPT"

add2iptables "INPUT -i lo -j ACCEPT"
add2ip6tables "INPUT -i lo -j ACCEPT"

HYSTRIA_TUIC_DOMAINS="$(hiddify_api hysteria-domain-port);$(hiddify_api hysteria-domain-port)"
for DOMAIN in ${HYSTRIA_TUIC_DOMAINS//;/ }; do
  IFS=':' read -ra PARTS <<<"$DOMAIN"
  port=${PARTS[1]}
  allow_port "udp" $port
done

# ICMP for ipv4
add2iptables "INPUT -p icmp -m icmp --icmp-type 0 -m conntrack --ctstate NEW -j ACCEPT"
add2iptables "INPUT -p icmp -m icmp --icmp-type 3 -m conntrack --ctstate NEW -j ACCEPT"
add2iptables "INPUT -p icmp -m icmp --icmp-type 11 -m conntrack --ctstate NEW -j ACCEPT"
add2iptables "INPUT -p icmp -m icmp --icmp-type 12 -m conntrack --ctstate NEW -j ACCEPT"

# ICMP for ipv6
add2ip6tables "INPUT -p ipv6-icmp --icmpv6-type 128 -m conntrack --ctstate NEW -j ACCEPT"
add2ip6tables "INPUT -p ipv6-icmp --icmpv6-type 129 -m conntrack --ctstate NEW -j ACCEPT"
add2ip6tables "INPUT -p ipv6-icmp --icmpv6-type 1 -m conntrack --ctstate NEW -j ACCEPT"
add2ip6tables "INPUT -p ipv6-icmp --icmpv6-type 4 -m conntrack --ctstate NEW -j ACCEPT"
add2ip6tables "INPUT -p ipv6-icmp --icmpv6-type 2 -m conntrack --ctstate NEW -j ACCEPT"

allow_apps_ports "sshd"
allow_apps_ports "x-ui"

add2iptables "INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT"
add2ip6tables "INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT"

add2iptables "INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
add2ip6tables "INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"

# Check if SSH server should be enabled
if [[ $ssh_server_enable == 'true' ]]; then
  allow_port "tcp" "$ssh_server_port"
else
  remove_port "tcp" "$ssh_server_port"
fi

TCP_PORTS=(${HTTP_PORTS//,/ } ${TLS_PORTS//,/ })
for PORT in "${TCP_PORTS[@]}"; do
  allow_port "tcp" $PORT
done

# Check if PasswordAuthentication is enabled
if ! grep -Fxq "PasswordAuthentication no" /etc/ssh/sshd_config; then
  # @hiddify/@iam54r1n4 make a better message with a link to why should disable pass-auth
  WARNING_MSG="Your server is vulnerable to abuses because PasswordAuthentication is enabled. To secure your server, please switch to key authentication mechanism and turn off PasswordAuthentication in your ssh config file."

  # Keep the orginal motd file as motd.org
  if [ -f /etc/motd ]; then
    MOTD_CONTENT=$(cat /etc/motd)
    if [[ "$MOTD_CONTENT" != "$WARNING_MSG" ]]; then
      mv /etc/motd /etc/motd.org
    fi
  fi

  # Create new /etc/motd file
  error "$WARNING_MSG" >/etc/motd 2>&1
else
  # Show orginal /etc/motd
  MOTD_CONTENT=$(cat /etc/motd)
  if [[ "$MOTD_CONTENT" == "$WARNING_MSG" ]]; then
    rm /etc/motd
    mv /etc/motd.org /etc/motd
  fi
fi
# Restart sshd/ssh
sudo systemctl restart sshd.service
sudo systemctl restart ssh.service

if [[ $ENABLE_FIREWALL == true ]]; then
  iptables -P INPUT DROP
  ip6tables -P INPUT DROP
  # ip6tables -P INPUT ACCEPT
else
  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  ip6tables -P INPUT ACCEPT
fi
iptables-save >/etc/iptables/rules.v4
awk -i inplace '!seen[$0]++' /etc/iptables/rules.v4
ip6tables-save >/etc/iptables/rules.v6
awk -i inplace '!seen[$0]++' /etc/iptables/rules.v6
ip6tables-restore </etc/iptables/rules.v6
iptables-restore </etc/iptables/rules.v4

#add2iptables "INPUT -p tcp --dport 9000 -j DROP"

if [[ $ENABLE_AUTO_UPDATE == true ]]; then
  echo "0 3 * * * root $(pwd)/../update.sh" >/etc/cron.d/hiddify_auto_update
  service cron reload
else
  rm -rf /etc/cron.d/hiddify_auto_update
  service cron reload
fi
