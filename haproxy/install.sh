source ../common/utils.sh
rm -rf *.template
if is_installed sniproxy; then
    # systemctl kill hiddify-sniproxy > /dev/null 2>&1
    systemctl stop hiddify-sniproxy >/dev/null 2>&1
    systemctl disable hiddify-sniproxy >/dev/null 2>&1
    pkill -9 sniproxy >/dev/null 2>&1
fi

OS_VERSION=$(lsb_release -rs | cut -d'.' -f1)
echo "Detected OS version: Ubuntu $OS_VERSION"
HAPROXY_VERSION=3.2
if [ "$OS_VERSION" -eq 22 ]; then
    HAPROXY_VERSION=3.0
    echo "OS version is 22, checking for haproxy=${HAPROXY_VERSION}"
fi
if ! is_installed_package "haproxy=${HAPROXY_VERSION}"; then
    echo "Adding PPA for haproxy-${HAPROXY_VERSION}"
    add-apt-repository -y ppa:vbernat/haproxy-${HAPROXY_VERSION}
    echo "Installing haproxy ${HAPROXY_VERSION}"
    install_package "haproxy=${HAPROXY_VERSION}.*"
else
    echo "haproxy ${HAPROXY_VERSION} is already installed"
fi
systemctl kill haproxy >/dev/null 2>&1
systemctl stop haproxy >/dev/null 2>&1
systemctl disable haproxy >/dev/null 2>&1

ln -sf $(pwd)/hiddify-haproxy.service /etc/systemd/system/hiddify-haproxy.service
systemctl enable hiddify-haproxy.service
