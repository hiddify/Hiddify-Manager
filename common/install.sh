apt --fix-broken install -y
sudo timedatectl set-timezone  Asia/Tehran
apt update
apt install -y at dialog apt-transport-https dnsutils ca-certificates git curl wget gnupg-agent software-properties-common  iptables locales lsof cron libssl-dev curl gnupg2 ca-certificates lsb-release ubuntu-keyring
sudo apt -y remove needrestart apache2
ln -sf $(pwd)/sysctl.conf /etc/sysctl.d/ss-opt.conf
sysctl --system
python3 -m pip config set global.index-url https://pypi.org/simple
if [[ "$ONLY_IPV4" != true ]];then
sysctl -w net.ipv6.conf.all.disable_ipv6=0
sysctl -w net.ipv6.conf.default.disable_ipv6=0
sysctl -w net.ipv6.conf.lo.disable_ipv6=0

curl --connect-timeout 1 -s http://ipv6.google.com 2>&1 >/dev/null
if [ $? != 0 ]; then
  ONLY_IPV4=true1
fi
fi

INT_STAT=0
INT_STAT_STR='Enable'
if [[ "$ONLY_IPV4" == true ]];then
INT_STAT=1
INT_STAT_STR="Disable"
fi

declare -a excluded_interfaces=("warp" "lo")

for interface_name in $(ip link | awk -F': ' '$2 ~ /^[[:alnum:]]+$/ {print $2}'); do
    if [[ " ${excluded_interfaces[@]} " =~ " ${interface_name} " ]]; then
        continue
    fi

    # Disable IPv6 for the current interface
    sysctl -q -w "net.ipv6.conf.$interface_name.disable_ipv6=$INT_STAT"

    if [ $? -eq 0 ]; then
        echo "IPv6 ${INT_STAT_STR}d for $interface_name"
    else
        echo "Failed to $INT_STAT_STR IPv6 for $interface_name"
    fi
done


  # sysctl -w net.ipv6.conf.all.disable_ipv6=1
  # sysctl -w net.ipv6.conf.default.disable_ipv6=1
  # sysctl -w net.ipv6.conf.lo.disable_ipv6=1
# else
#   sysctl -w net.ipv6.conf.all.disable_ipv6=0
#   sysctl -w net.ipv6.conf.default.disable_ipv6=0
#   sysctl -w net.ipv6.conf.lo.disable_ipv6=0
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

# which warp-go
# if [ $? != 0 ];then
#   wget -N https://raw.githubusercontent.com/fscarmen/warp/main/warp-go.sh && echo "13"| bash warp-go.sh n
# fi
# echo 3|warp-go a

# ping 8.8.8.0  -I 172.16.0.2 -c 4 -W 0.5
# first_test=$?
# nslookup yahoo.com
# if [ $? != 0 || $first_test != 0 ];then
#   warp-go u
# fi





grep -qxF 'DNS=resolve ipv4' /etc/systemd/resolved.conf || echo "DNS=resolve ipv4" >> /etc/systemd/resolved.conf

systemctl restart systemd-resolved




echo "hiddify-panel ALL=(root) NOPASSWD: /opt/hiddify-config/install.sh" > /etc/sudoers.d/hiddify
echo "hiddify-panel ALL=(root) NOPASSWD: /opt/hiddify-config/status.sh" >> /etc/sudoers.d/hiddify
echo "hiddify-panel ALL=(root) NOPASSWD: /opt/hiddify-config/update.sh" >> /etc/sudoers.d/hiddify
echo "hiddify-panel ALL=(root) NOPASSWD: /opt/hiddify-config/apply_configs.sh" >> /etc/sudoers.d/hiddify
echo "hiddify-panel ALL=(root) NOPASSWD: /opt/hiddify-config/hiddify-panel/temporary_access.sh" >> /etc/sudoers.d/hiddify
echo "hiddify-panel ALL=(root) NOPASSWD: /opt/hiddify-config/hiddify-panel/update_usage.sh" >> /etc/sudoers.d/hiddify
echo "hiddify-panel ALL=(root) NOPASSWD: /opt/hiddify-config/hiddify-panel/restart.sh" >> /etc/sudoers.d/hiddify
echo "hiddify-panel ALL=(root) NOPASSWD: /opt/hiddify-config/nginx/add2shortlink.sh" >> /etc/sudoers.d/hiddify



ln -sf /opt/hiddify-config/menu.sh /usr/bin/hiddify