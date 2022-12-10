sudo timedatectl set-timezone  Asia/Tehran

apt install -y apt-transport-https dnsutils ca-certificates git curl wget gnupg-agent software-properties-common  iptables

ln -s $(pwd)/sysctl.conf /etc/sysctl.d/ss-opt.conf
sysctl --system



bash google-bbr.sh



 if [[ $ENABLE_FIREWALL == true ]]; then
  iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  iptables -I INPUT -i lo -j ACCEPT
  iptables -I INPUT -p tcp --dport 443 -j ACCEPT
  iptables -I INPUT -p udp --dport 53 -j ACCEPT
  iptables -I INPUT -p tcp --dport 80 -j ACCEPT
  iptables -I INPUT -p tcp --dport 22 -j ACCEPT
  iptables -P INPUT DROP
  iptables-save > /etc/iptables/rules.v4 

fi

if [[ $ENABLE_AUTO_UPDATE == true ]]; then
  echo "0 3 * * * root $(pwd)/update_cron.sh" > /etc/cron.d/hiddify_auto_update
  service cron reload
fi