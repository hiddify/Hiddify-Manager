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
add2iptables "INPUT -p tcp --dport 53 -j ACCEPT"
add2iptables "INPUT -p tcp --dport 80 -j ACCEPT"
add2iptables "INPUT -p tcp --dport 22 -j ACCEPT"
add2iptables "INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
ip6tables -A INPUT -p icmpv6 --icmpv6-type 128 -j ACCEPT

add2iptables "INPUT -p icmp -m icmp --icmp-type 0 -m conntrack --ctstate NEW -j ACCEPT"
add2iptables "INPUT -p icmp -m icmp --icmp-type 3 -m conntrack --ctstate NEW -j ACCEPT"
add2iptables "INPUT -p icmp -m icmp --icmp-type 11 -m conntrack --ctstate NEW -j ACCEPT"
add2iptables "INPUT -p icmp -m icmp --icmp-type 12 -m conntrack --ctstate NEW -j ACCEPT"
add2iptables "INPUT -p tcp -m tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT"
add2iptables "INPUT -p tcp -m tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT"

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
  # ip6tables -P INPUT DROP
  ip6tables -P INPUT ACCEPT
else
  iptables -P INPUT ACCEPT
  ip6tables -P INPUT ACCEPT
fi
iptables-save >/etc/iptables/rules.v4
awk -i inplace '!seen[$0]++' /etc/iptables/rules.v4
ip6tables-save >/etc/iptables/rules.v6
awk -i inplace '!seen[$0]++' /etc/iptables/rules.v6
ip6tables-restore </etc/iptables/rules.v6
iptables-restore </etc/iptables/rules.v4

awk -i inplace '!seen[$0]++' /etc/iptables/rules.v6
#add2iptables "INPUT -p tcp --dport 9000 -j DROP"

if [[ $ENABLE_AUTO_UPDATE == true ]]; then
  echo "0 3 * * * root $(pwd)/../update.sh" >/etc/cron.d/hiddify_auto_update
  service cron reload
else
  rm -rf /etc/cron.d/hiddify_auto_update
  service cron reload
fi

:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [388:50926]
:ICMPFLOOD - [0:0]
:INVALIDDROP - [0:0]
:InstanceServices - [0:0]
:PORTSCAN - [0:0]
:SSHBRUTE - [0:0]
-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
-A INPUT -p udp -m udp --dport 53 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 19527 -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m tcp --dport 6009 -j ACCEPT
-A INPUT -p udp -m udp --dport 3478 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 15767 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 5499 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 14074 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 12154 -j ACCEPT
-A INPUT -s 127.0.0.0/8 ! -i lo -j DROP
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -m icmp --icmp-type 0 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p icmp -m icmp --icmp-type 3 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p icmp -m icmp --icmp-type 11 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p icmp -m icmp --icmp-type 12 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p icmp -m icmp --icmp-type 8 -m conntrack --ctstate NEW -j ICMPFLOOD
-A INPUT -m state --state INVALID -j INVALIDDROP
-A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j PORTSCAN
-A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN -j PORTSCAN
-A INPUT -p tcp -m tcp --tcp-flags FIN,SYN FIN,SYN -j PORTSCAN
-A INPUT -p tcp -m tcp --tcp-flags SYN,RST SYN,RST -j PORTSCAN
-A INPUT -p tcp -m tcp --tcp-flags FIN,RST FIN,RST -j PORTSCAN
-A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,PSH,URG -j PORTSCAN
-A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j PORTSCAN
-A INPUT -p tcp -m tcp --tcp-flags FIN,ACK FIN -j PORTSCAN
-A INPUT -p tcp -m tcp --tcp-flags PSH,ACK PSH -j PORTSCAN
-A INPUT -p tcp -m tcp --tcp-flags ACK,URG URG -j PORTSCAN
-A INPUT -p tcp -m tcp --dport 22 -m conntrack --ctstate NEW -j SSHBRUTE
-A INPUT -p tcp -m tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p tcp -m tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p tcp -m tcp --dport 993 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p tcp -m tcp --dport 8443 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10000 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -j DROP
-A ICMPFLOOD -m recent --set --name ICMP --mask 255.255.255.255 --rsource
-A ICMPFLOOD -m recent --update --seconds 1 --hitcount 5 --rttl --name ICMP --mask 255.255.255.255 --rsource -j DROP
-A ICMPFLOOD -j ACCEPT
-A INVALIDDROP -m state --state INVALID -j DROP
-A PORTSCAN -j DROP
-A SSHBRUTE -m recent --set --name SSH --mask 255.255.255.255 --rsource
-A SSHBRUTE -m recent --update --seconds 60 --hitcount 5 --name SSH --mask 255.255.255.255 --rsource -j DROP
-A SSHBRUTE -j ACCEPT
