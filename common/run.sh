function add2iptables() {
  iptables -C $1 || echo "adding rule $1" && iptables -I $1
  add2ip6tables "$1"
}

function add2ip6tables() {
  ip6tables -C $1 || echo "adding rule $1" && ip6tables -I $1
}

function allow_apps_ports() {
  service_name=$1

  port=$(ss -tulpn | grep "$service_name" | awk '{print $5}' | cut -d':' -f2)
  if [[ -z $port ]]; then
    echo "Service not found or not running"
  else
    pid=$(ss -tulpn | grep "$service_name" | awk '{print $5}' | cut -d':' -f2 | sed 's/)//')
    path=$(ps -aux | grep $service_name | awk '{print $11}')
    for p in $port; do
      echo "Service is running on port $p and path $path"
      add2iptables "INPUT -p tcp --dport $port -j ACCEPT"
      # if [[ $1 == 'sshd' ]];then
      #   add2iptables "INPUT -p tcp -m tcp --dport $PORT -m conntrack --ctstate NEW -j SSHBRUTE"
      #   add2ip6tables "INPUT -p tcp -m tcp --dport $PORT -m conntrack --ctstate NEW -j SSHBRUTE"
      # else
      # add2iptables "INPUT -p tcp -m tcp --dport $PORT -m conntrack --ctstate NEW -j ACCEPT"
      # add2ip6tables "INPUT -p tcp -m tcp --dport $PORT -m conntrack --ctstate NEW -j ACCEPT"
      # fi
    done
  fi
}

mkdir -p /etc/iptables/

add2iptables "INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT"
add2iptables "INPUT -i lo -j ACCEPT"
add2iptables "INPUT -p tcp --dport 443 -j ACCEPT"
# add2iptables "INPUT -p udp --dport 443 -j ACCEPT"
# add2iptables "INPUT -p udp --dport 3478 -j ACCEPT"
if [[ $ssh_server_enable == 'true' ]]; then
  add2iptables "INPUT -p tcp --dport ${ssh_server_port} -j ACCEPT"
else
  iptables -D INPUT -p tcp --dport ${ssh_server_port}
fi
add2iptables "INPUT -p udp --dport 53 -j ACCEPT"
add2iptables "INPUT -p tcp --dport 80 -j ACCEPT"
add2iptables "INPUT -p tcp --dport 22 -j ACCEPT"
allow_apps_ports "sshd"
allow_apps_ports "x-ui"
# allow_apps_ports "ssh-liberty-bridge"
for PORT in ${HTTP_PORTS//,/ }; do
  add2iptables "INPUT -p tcp --dport $PORT -j ACCEPT"
done
for PORT in ${TLS_PORTS//,/ }; do
  add2iptables "INPUT -p tcp --dport $PORT -j ACCEPT"
done

mkdir -p /etc/iptables/
if [[ $ENABLE_FIREWALL == true ]]; then
  iptables -P INPUT DROP
  ip6tables -P INPUT DROP
else
  iptables -P INPUT ACCEPT
  ip6tables -P INPUT ACCEPT
fi
iptables-save >/etc/iptables/rules.v4
awk -i inplace '!seen[$0]++' /etc/iptables/rules.v4
ip6tables-save >/etc/iptables/rules.v6
awk -i inplace '!seen[$0]++' /etc/iptables/rules.v6
ip6tables-restore</etc/iptables/rules.v6
iptables-restore</etc/iptables/rules.v4


awk -i inplace '!seen[$0]++' /etc/iptables/rules.v6
#add2iptables "INPUT -p tcp --dport 9000 -j DROP"

if [[ $ENABLE_AUTO_UPDATE == true ]]; then
  echo "0 3 * * * root $(pwd)/../update.sh" >/etc/cron.d/hiddify_auto_update
  service cron reload
else
  rm -rf /etc/cron.d/hiddify_auto_update
  service cron reload
fi
