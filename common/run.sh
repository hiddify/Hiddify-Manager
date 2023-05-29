function add2iptables(){
  iptables -C $1 || echo "adding rule $1" && iptables -I $1
}

function add2ip6tables(){
  ip6tables -C $1 || echo "adding rule $1" && ip6tables -I $1
}

function allow_apps_ports(){
   service_name=$1

  port=$(ss -tulpn | grep "$service_name" | awk '{print $5}' | cut -d':' -f2)
  if [[ -z $port ]]
  then
    echo "Service not found or not running"
  else
    pid=$(ss -tulpn | grep "$service_name" | awk '{print $5}' | cut -d':' -f2 | sed 's/)//')
    path=$(ps -aux | grep $service_name | awk '{print $11}')
    for p in $port;do
      echo "Service is running on port $p and path $path"
      #add2iptables "INPUT -p tcp --dport $port -j ACCEPT"
	  add2iptables "INPUT -p tcp -m tcp --dport $PORT -m conntrack --ctstate NEW -j ACCEPT"
    done
  fi
}

mkdir -p /etc/iptables/

 if [[ $ENABLE_FIREWALL == true ]]; then
  iptables -P INPUT ACCEPT
  iptables -F
  iptables -N ICMPFLOOD
  iptables -N INVALIDDROP
  iptables -N PORTSCAN
  iptables -N SSHBRUTE
  
  add2iptables "SSHBRUTE -j ACCEPT"
  add2iptables "SSHBRUTE -m recent --update --seconds 60 --hitcount 5 --name SSH --mask 255.255.255.255 --rsource -j DROP"
  add2iptables "SSHBRUTE -m recent --update --seconds 60 --hitcount 5 --name SSH --mask 255.255.255.255 --rsource -m limit --limit 1/sec -j LOG --log-prefix\"ssh-brute blocked: \""
  add2iptables "SSHBRUTE -m recent --set --name SSH --mask 255.255.255.255 --rsource"
  add2iptables "PORTSCAN -j DROP"
  add2iptables "PORTSCAN -m limit --limit 1/sec -j LOG --log-prefix\"port scan blocked: \""
  add2iptables "INVALIDDROP -m state --state INVALID -j DROP"
  add2iptables "INVALIDDROP -m state --state INVALID -m limit --limit 1/sec -j LOG --log-prefix\"invalid packet block\""
  add2iptables "ICMPFLOOD -j ACCEPT"
  add2iptables "ICMPFLOOD -m recent --update --seconds 1 --hitcount 5 --rttl --name ICMP --mask 255.255.255.255 --rsource -j DROP"
  add2iptables "ICMPFLOOD -m limit --limit 1/sec -m recent --update --seconds 1 --hitcount 5 --rttl --name ICMP --mask 255.255.255.255 --rsource -j LOG --log-prefix\"icmp-flood blocked: \""
  add2iptables "ICMPFLOOD -m recent --set --name ICMP --mask 255.255.255.255 --rsource"
  add2iptables "INPUT -j DROP"
  allow_apps_ports "x-ui"
  allow_apps_ports "sshd"
  # add2iptables "INPUT -p udp --dport 443 -j ACCEPT"
  add2iptables "INPUT -p udp --dport 3478 -j ACCEPT"
  add2iptables "INPUT -p udp --dport 53 -j ACCEPT"
  add2iptables "INPUT -p tcp -m tcp --dport 10000 -m conntrack --ctstate NEW -j ACCEPT"
  add2iptables "INPUT -p tcp -m tcp --dport 8443 -m conntrack --ctstate NEW -j ACCEPT"
  add2iptables "INPUT -p tcp -m tcp --dport 993 -m conntrack --ctstate NEW -j ACCEPT"

  for PORT in ${TLS_PORTS//,/ };	do 
    #add2iptables "INPUT -p tcp --dport $PORT -j ACCEPT"
	add2iptables "INPUT -p tcp -m tcp --dport $PORT -m conntrack --ctstate NEW -j ACCEPT"
  done
  for PORT in ${HTTP_PORTS//,/ };	do 
    #add2iptables "INPUT -p tcp --dport $PORT -j ACCEPT"
	add2iptables "INPUT -p tcp -m tcp --dport $PORT -m conntrack --ctstate NEW -j ACCEPT"
  done

  add2iptables "INPUT -p tcp -m tcp --dport 22 -m conntrack --ctstate NEW -j SSHBRUTE"
  add2iptables "INPUT -p tcp -m tcp --tcp-flags ACK,URG URG -j PORTSCAN"
  add2iptables "INPUT -p tcp -m tcp --tcp-flags PSH,ACK PSH -j PORTSCAN"
  add2iptables "INPUT -p tcp -m tcp --tcp-flags FIN,ACK FIN -j PORTSCAN"
  add2iptables "INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j PORTSCAN"
  add2iptables "INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j PORTSCAN"
  add2iptables "INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,PSH,URG -j PORTSCAN"
  add2iptables "INPUT -p tcp -m tcp --tcp-flags FIN,RST FIN,RST -j PORTSCAN"
  add2iptables "INPUT -p tcp -m tcp --tcp-flags SYN,RST SYN,RST -j PORTSCAN"
  add2iptables "INPUT -p tcp -m tcp --tcp-flags FIN,SYN FIN,SYN -j PORTSCAN"
  add2iptables "INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN -j PORTSCAN"
  add2iptables "INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j PORTSCAN"
  add2iptables "INPUT -m state --state INVALID -j INVALIDDROP"
  add2iptables "INPUT -p icmp -m icmp --icmp-type 8 -m conntrack --ctstate NEW -j ICMPFLOOD"
  add2iptables "INPUT -p icmp -m icmp --icmp-type 12 -m conntrack --ctstate NEW -j ACCEPT"
  add2iptables "INPUT -p icmp -m icmp --icmp-type 11 -m conntrack --ctstate NEW -j ACCEPT"
  add2iptables "INPUT -p icmp -m icmp --icmp-type 3 -m conntrack --ctstate NEW -j ACCEPT"
  add2iptables "INPUT -p icmp -m icmp --icmp-type 0 -m conntrack --ctstate NEW -j ACCEPT"
  add2iptables "INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
  add2iptables "INPUT -s 127.0.0.0/8 ! -i lo -j DROP"
  add2iptables "INPUT -i lo -j ACCEPT"
  
  #iptables -P INPUT DROP
  iptables-save > /etc/iptables/rules.v4 
else 
  iptables -P INPUT ACCEPT
  iptables -F
  iptables-save > /etc/iptables/rules.v4 
fi

 if [[ $ENABLE_FIREWALL == true ]]; then
  ip6tables -P INPUT ACCEPT
  ip6tables -F
  ip6tables -N ICMPFLOOD
  ip6tables -N INVALIDDROP
  ip6tables -N PORTSCAN
  ip6tables -N SSHBRUTE

  add2ip6tables "SSHBRUTE -j ACCEPT"
  add2ip6tables "SSHBRUTE -m recent --update --seconds 60 --hitcount 5 --name SSH --mask ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff --rsource -j DROP"
  add2ip6tables "SSHBRUTE -m recent --update --seconds 60 --hitcount 5 --name SSH --mask ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff --rsource -m limit --limit 1/sec -j LOG --log-prefix\"ssh-brute blocked: \""
  add2ip6tables "SSHBRUTE -m recent --set --name SSH --mask ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff --rsource"
  add2ip6tables "PORTSCAN -j DROP"
  add2ip6tables "PORTSCAN -m limit --limit 1/sec -j LOG --log-prefix\"port scan blocked: \""
  add2ip6tables "INVALIDDROP -m state --state INVALID -j DROP"
  add2ip6tables "INVALIDDROP -m state --state INVALID -m limit --limit 1/sec -j LOG --log-prefix\"invalid packet block\""
  add2ip6tables "ICMPFLOOD -j ACCEPT"
  add2ip6tables "ICMPFLOOD -m recent --update --seconds 1 --hitcount 5 --rttl --name ICMP --mask ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff --rsource -j DROP"
  add2ip6tables "ICMPFLOOD -m recent --update --seconds 1 --hitcount 5 --rttl --name ICMP --mask ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff --rsource -m limit --limit 1/sec -j LOG --log-prefix\"icmp-flood blocked: \""
  add2ip6tables "ICMPFLOOD -m recent --set --name ICMP --mask ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff --rsource"
  add2ip6tables "INPUT -j DROP"
  add2ip6tables "INPUT -p tcp -m tcp --dport 10000 -m conntrack --ctstate NEW -j ACCEPT"
  add2ip6tables "INPUT -p tcp -m tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT"
  add2ip6tables "INPUT -p tcp -m tcp --dport 22 -m conntrack --ctstate NEW -j SSHBRUTE"
  add2ip6tables "INPUT -p tcp -m tcp --tcp-flags ACK,URG URG -j PORTSCAN"
  add2ip6tables "INPUT -p tcp -m tcp --tcp-flags PSH,ACK PSH -j PORTSCAN"
  add2ip6tables "INPUT -p tcp -m tcp --tcp-flags FIN,ACK FIN -j PORTSCAN"
  add2ip6tables "INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j PORTSCAN"
  add2ip6tables "INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j PORTSCAN"
  add2ip6tables "INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,PSH,URG -j PORTSCAN"
  add2ip6tables "INPUT -p tcp -m tcp --tcp-flags FIN,RST FIN,RST -j PORTSCAN"
  add2ip6tables "INPUT -p tcp -m tcp --tcp-flags SYN,RST SYN,RST -j PORTSCAN"
  add2ip6tables "INPUT -p tcp -m tcp --tcp-flags FIN,SYN FIN,SYN -j PORTSCAN"
  add2ip6tables "INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN -j PORTSCAN"
  add2ip6tables "INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j PORTSCAN"
  add2ip6tables "INPUT -m state --state INVALID -j INVALIDDROP"
  add2ip6tables "INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 128 -j ICMPFLOOD"
  add2ip6tables "INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 136 -j ACCEPT"
  add2ip6tables "INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 135 -j ACCEPT"
  add2ip6tables "INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 134 -j ACCEPT"
  add2ip6tables "INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 133 -j ACCEPT"
  add2ip6tables "INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 129 -j ACCEPT"
  add2ip6tables "INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 128 -j ACCEPT"
  add2ip6tables "INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 4 -j ACCEPT"
  add2ip6tables "INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 3 -j ACCEPT"
  add2ip6tables "INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 2 -j ACCEPT"
  add2ip6tables "INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 1 -j ACCEPT"
  add2ip6tables "INPUT -s ::1/128 ! -i lo -j DROP"
  add2ip6tables "INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
  add2ip6tables "INPUT -i lo -j ACCEPT"

  #ip6tables -P INPUT DROP
  ip6tables-save > /etc/iptables/rules.v6 
else 
  ip6tables -P INPUT ACCEPT
  ip6tables -F
  ip6tables-save > /etc/iptables/rules.v6 
fi

#add2iptables "INPUT -p tcp --dport 9000 -j DROP"

if [[ $ENABLE_AUTO_UPDATE == true ]]; then
  echo "0 3 * * * root $(pwd)/../update.sh" > /etc/cron.d/hiddify_auto_update
  service cron reload
else
  rm -rf /etc/cron.d/hiddify_auto_update
  service cron reload
fi
