#!/bin/bash
source utils.sh
remove_package apache2 needrestart needrestart-session
install_package apt-transport-https apt-utils at build-essential ca-certificates cron curl default-libmysqlclient-dev dnsutils gawk git gnupg-agent gnupg2 iproute2 iptables jq less libev-dev libevdev2 libssl-dev locales lsb-release lsof pkg-config qrencode software-properties-common sudo ubuntu-keyring wget whiptail
activate_python_venv
#python -m pip config set global.index-url https://pypi.org/simple > /dev/null
# remove_package resolvconf
# rm /etc/resolv.conf
# ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf



groupadd -f hiddify-common
usermod -aG hiddify-common root

# rm /run/resolvconf/interface/*
#echo "nameserver 8.8.8.8" >/etc/resolv.conf
#echo "nameserver 1.1.1.1" >>/etc/resolv.conf
#echo "nameserver 8.8.8.8" >/etc/resolvconf/resolv.conf.d/base
#echo "nameserver 1.1.1.1" >>/etc/resolvconf/resolv.conf.d/base
#resolvconf -u
sudo systemctl unmask --now systemd-resolved.service
systemctl enable --now systemd-resolved >/dev/null 2>&1

# install requirements for change_dns.py
install_pypi_package pyyaml > /dev/null
if ! nslookup google.com &> /dev/null; then
    warning "DNS is not working."
    ./change_dns.py 8.8.8.8 1.1.1.1
fi


ln -sf $(pwd)/sysctl.conf /etc/sysctl.d/hiddify.conf

if [ "${MODE}" != "docker" ];then
  sysctl --system > /dev/null
fi

if [[ "$ONLY_IPV4" != true ]]; then
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
if [[ "$ONLY_IPV4" == true ]]; then
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

bash google-bbr.sh > /dev/null


echo "@reboot root /opt/hiddify-manager/install.sh --no-gui --no-log >> /opt/hiddify-manager/log/system/reboot.log 2>&1" >/etc/cron.d/hiddify_reinstall_on_reboot
echo "@daily root /opt/hiddify-manager/common/daily_actions.sh >> /opt/hiddify-manager/log/system/daily_actions.log 2>&1" >/etc/cron.d/hiddify_daily_memory_release
service cron reload

if [ "${MODE}" != "docker" ];then
  localectl set-locale LANG=C.UTF-8
fi

update-locale LANG=C.UTF-8

echo "hiddify-panel ALL=(root) NOPASSWD: /opt/hiddify-manager/common/commander.py" >/etc/sudoers.d/hiddify

ln -sf /opt/hiddify-manager/menu.sh /usr/bin/hiddify

systemctl disable --now rpcbind.socket >/dev/null 2>&1
systemctl disable --now rpcbind >/dev/null 2>&1
