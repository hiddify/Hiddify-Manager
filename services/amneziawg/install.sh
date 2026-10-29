source /opt/hiddify-manager/scripts/common/utils.sh
source ./awg_utils.sh

# AmneziaWG is not in the distribution: the Amnezia PPA has the kernel module (amneziawg-dkms, built for the running
# kernel, so its headers are needed) and the tools (awg, awg-quick). In Docker the module comes from the host.
if ! command -v awg-quick >/dev/null 2>&1; then
    source /etc/os-release
    if [ "$ID" != "ubuntu" ]; then
        error "AmneziaWG: only Ubuntu is supported (the Amnezia PPA); install amneziawg yourself on $PRETTY_NAME"
        exit 1
    fi
    install_package software-properties-common
    add-apt-repository -y ppa:amnezia/ppa || {
        error "AmneziaWG: could not add ppa:amnezia/ppa"
        exit 1
    }
    apt-get update
fi

if [ "$DOCKER_MODE" == "true" ]; then
    install_package amneziawg-tools
else
    # Headers of the running kernel, so dkms can build the module (cloud kernels may not have them in apt)
    install_package "linux-headers-$(uname -r)" || echo "AmneziaWG: no headers package for kernel $(uname -r); the module may not build"
    install_package amneziawg
fi

echo "net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1" >/etc/sysctl.d/awg.conf

if [ "$MODE" != "docker" ]; then
    sysctl --system >/dev/null
    modprobe amneziawg 2>/dev/null || echo "AmneziaWG: the amneziawg kernel module is not loaded (reboot after a kernel update?)"
fi

systemctl enable "$AWG_UNIT"
