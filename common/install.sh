
sudo timedatectl set-timezone  Asia/Tehran

apt install -y apt-transport-https dnsutils ca-certificates git curl wget gnupg-agent software-properties-common  iptables
sudo apt -y remove needrestart
ln -s $(pwd)/sysctl.conf /etc/sysctl.d/ss-opt.conf
sysctl --system

if [[ $ONLY_IPV4 == true ]];then
  sysctl -w net.ipv6.conf.all.disable_ipv6=1
  sysctl -w net.ipv6.conf.default.disable_ipv6=1
  sysctl -w net.ipv6.conf.lo.disable_ipv6=1
fi

bash google-bbr.sh

function add2iptables(){
  iptables -C $1 || echo "adding rule $1" && iptables -I $1
}

 if [[ $ENABLE_FIREWALL == true ]]; then
  add2iptables "INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT"
  add2iptables "INPUT -i lo -j ACCEPT"
  add2iptables "INPUT -p tcp --dport 443 -j ACCEPT"
  add2iptables "INPUT -p udp --dport 53 -j ACCEPT"
  add2iptables "INPUT -p tcp --dport 80 -j ACCEPT"
  add2iptables "INPUT -p tcp --dport 22 -j ACCEPT"
  iptables -P INPUT DROP
  iptables-save > /etc/iptables/rules.v4 

fi

if [[ $ENABLE_AUTO_UPDATE == true ]]; then
  echo "0 3 * * * root $(pwd)/../update.sh" > /etc/cron.d/hiddify_auto_update
  service cron reload
else
  rm -rf /etc/cron.d/hiddify_auto_update
  service cron reload
fi