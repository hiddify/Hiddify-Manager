apt install -y netdata

echo "" >/etc/netdata/apps_groups.conf



# echo "containers: lxc* docker* balena*" >>/etc/netdata/apps_groups.conf
# echo "ssh: ssh* scp dropbear" >>/etc/netdata/apps_groups.conf







echo "system: systemd-* udisks* udevd* *udevd connmand ipv6_addrconf dbus-* rtkit*" >>/etc/netdata/apps_groups.conf
echo "system: inetd xinetd mdadm polkitd acpid uuidd packagekitd upowerd colord" >>/etc/netdata/apps_groups.conf
echo "system: accounts-daemon rngd haveged" >>/etc/netdata/apps_groups.conf
echo "kernel: kthreadd kauditd lockd khelper kdevtmpfs khungtaskd rpciod" >>/etc/netdata/apps_groups.conf
echo "kernel: fsnotify_mark kthrotld deferwq scsi_*" >>/etc/netdata/apps_groups.conf


echo "shadowsocks: obfs* shadowsocks*" >>/etc/netdata/apps_groups.conf
echo "netdata: netdata" >>/etc/netdata/apps_groups.conf
echo "python: python*" >>/etc/netdata/apps_groups.conf
echo "logs: ulogd* syslog* rsyslog* logrotate systemd-journald rotatelogs" >>/etc/netdata/apps_groups.conf

echo "cron: cron* atd anacron systemd-cron* incrond" >>/etc/netdata/apps_groups.conf
echo "nginx: nginx" >>/etc/netdata/apps_groups.conf
echo "telegram-proxy: mtg mtprotoproxy* mtproto-proxy mtp_proxy" >>/etc/netdata/apps_groups.conf

echo "hiddify-xray: xray*" >>/etc/netdata/apps_groups.conf
echo "hiddify-panel: *unicorn* hiddifypanel" >>/etc/netdata/apps_groups.conf
echo "hiddify-sniproxy: sniproxy*" >>/etc/netdata/apps_groups.conf