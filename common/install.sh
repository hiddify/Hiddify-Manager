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
sysctl -w fs.file-max=51200
sysctl -w net.core.rmem_max=67108864
sysctl -w net.core.wmem_max=67108864
sysctl -w net.core.rmem_default=65536
sysctl -w net.core.wmem_default=65536
sysctl -w net.core.netdev_max_backlog=250000
sysctl -w net.core.somaxconn=4096
sysctl -w net.ipv4.tcp_syncookies=1
sysctl -w net.ipv4.tcp_tw_reuse=1
sysctl -w net.ipv4.tcp_fin_timeout=30
sysctl -w net.ipv4.tcp_keepalive_time=1200
sysctl -w net.ipv4.tcp_max_syn_backlog=8192
sysctl -w net.ipv4.tcp_max_tw_buckets=5000
sysctl -w net.ipv4.tcp_fastopen=3
sysctl -w net.ipv4.tcp_mem=24600 51200 102400
sysctl -w net.ipv4.tcp_rmem=4096 87380 67108864
sysctl -w net.ipv4.tcp_wmem=4096 65536 67108864
sysctl -w net.ipv4.tcp_mtu_probing=1
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.netfilter.nf_conntrack_max=2097152
sysctl -w net.netfilter.nf_conntrack_tcp_timeout_close_wait=60
sysctl -w net.netfilter.nf_conntrack_tcp_timeout_fin_wait=60
sysctl -w net.netfilter.nf_conntrack_tcp_timeout_time_wait=60
bash google-bbr.sh

sysctl -w net.ipv4.conf.all.route_localnet=1

echo "@reboot root /opt/hiddify-config/install.sh >> /opt/hiddify-config/log/system/reboot.log 2>&1" > /etc/cron.d/hiddify_reinstall_on_reboot
echo "@daily root /opt/hiddify-config/common/daily_actions.sh >> /opt/hiddify-config/log/system/daily_actions.log 2>&1" > /etc/cron.d/hiddify_daily_memory_release
service cron reload


localectl set-locale LANG=C.UTF-8
update-locale LANG=C.UTF-8
#wget -N https://raw.githubusercontent.com/fscarmen/warp/main/warp-go.sh && echo "13"| bash warp-go.sh d

