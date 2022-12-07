apt install -y apt-transport-https dnsutils ca-certificates git curl wget gnupg-agent software-properties-common 

ln -s $(pwd)/sysctl.conf /etc/sysctl.d/ss-opt.conf
sysctl --system

bash google-bbr.sh



 if [[ $ENABLE_FIREWALL == true ]]; then
  iptables -I INPUT -p tcp --dport 443 -j ACCEPT
  iptables -I INPUT -p tcp --dport 80 -j ACCEPT
  iptables -I INPUT -p tcp --dport 22 -j ACCEPT
  iptables -P INPUT DROP
fi