apt install -y apt-transport-https dnsutils ca-certificates git curl wget gnupg-agent software-properties-common 

ln -s $(pwd)/sysctl.conf /etc/sysctl.d/ss-opt.conf
sysctl --system

bash google-bbr.sh
