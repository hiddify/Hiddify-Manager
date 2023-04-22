apt --fix-broken install -y
sudo timedatectl set-timezone  Asia/Tehran
apt update
apt install -y at dialog apt-transport-https dnsutils ca-certificates git curl wget gnupg-agent software-properties-common  iptables locales lsof cron libssl-dev
sudo apt -y remove needrestart apache2
ln -sf $(pwd)/sysctl.conf /etc/sysctl.d/ss-opt.conf
sysctl --system

if [[ $ONLY_IPV4 == true ]];then
  sysctl -w net.ipv6.conf.all.disable_ipv6=1
  sysctl -w net.ipv6.conf.default.disable_ipv6=1
  sysctl -w net.ipv6.conf.lo.disable_ipv6=1
else
  sysctl -w net.ipv6.conf.all.disable_ipv6=0
  sysctl -w net.ipv6.conf.default.disable_ipv6=0
  sysctl -w net.ipv6.conf.lo.disable_ipv6=0
fi

bash google-bbr.sh

sysctl -w net.ipv4.conf.all.route_localnet=1

echo "@reboot root /opt/hiddify-config/install.sh >> /opt/hiddify-config/log/system/reboot.log 2>&1" > /etc/cron.d/hiddify_reinstall_on_reboot
echo "@daily root /opt/hiddify-config/common/daily_actions.sh >> /opt/hiddify-config/log/system/daily_actions.log 2>&1" > /etc/cron.d/hiddify_daily_memory_release
service cron reload


localectl set-locale LANG=C.UTF-8
update-locale LANG=C.UTF-8
#wget -N https://raw.githubusercontent.com/fscarmen/warp/main/warp-go.sh && echo "13"| bash warp-go.sh d

