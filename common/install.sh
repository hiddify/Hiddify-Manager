apt install -y apt-transport-https dnsutils ca-certificates git curl wget gnupg-agent software-properties-common  iptables

ln -s $(pwd)/sysctl.conf /etc/sysctl.d/ss-opt.conf
sysctl --system

bash google-bbr.sh



 if [[ $ENABLE_FIREWALL == true ]]; then
  iptables -I INPUT -p tcp --dport 443 -j ACCEPT
  iptables -I INPUT -p tcp --dport 80 -j ACCEPT
  iptables -I INPUT -p tcp --dport 22 -j ACCEPT
  iptables -P INPUT DROP
  iptables-save > /etc/iptables/rules.v4 
  ( iptables -I INPUT -p tcp  --dport 500 -j ACCEPT ; sleep 1h; iptables -D INPUT -p tcp --dport 500 -j ACCEPT ) &

fi

if [[ $ENABLE_AUTO_UPDATE == true ]]; then
  echo "0 3 * * * root $(pwd)/update_cron.sh" > /etc/cron.d/hiddify_auto_update
  service cron reload
fi