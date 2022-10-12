
ln -s $(pwd)/sysctl.conf /etc/sysctl.d/ss-opt.conf
sysctl --system

bash google-bbr.sh
