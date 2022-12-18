systemctl stop systemd-resolved && systemctl disable systemd-resolved && rm -rf /etc/resolv.conf && echo 'nameserver 8.8.8.8'>/etc/resolv.conf

wget --no-check-certificate -O dnsmasq_sniproxy.sh https://raw.githubusercontent.com/myxuchangbin/dnsmasq_sniproxy_install/master/dnsmasq_sniproxy.sh && bash dnsmasq_sniproxy.sh -f