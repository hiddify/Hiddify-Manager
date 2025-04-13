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

if [ "$OS_VERSION" -eq 22 ]; then
    echo "OS version is 22, checking for haproxy=3.0"
    if ! is_installed_package "haproxy=3.0"; then
        echo "Adding PPA for haproxy-3.0"
        add-apt-repository -y ppa:vbernat/haproxy-3.0
        echo "Installing haproxy 3.0"
        install_package haproxy=3.0.*
    else
        echo "haproxy 3.0 is already installed"
    fi
elif [ "$OS_VERSION" -eq 24 ]; then
    echo "OS version is 24, checking for haproxy=3.1"
    if ! is_installed_package "haproxy=3.1"; then
        echo "Adding PPA for haproxy-3.1"
        add-apt-repository -y ppa:vbernat/haproxy-3.1
        echo "Installing haproxy 3.1"
        install_package haproxy=3.1.*
    else
        echo "haproxy 3.1 is already installed"
    fi
else
    echo "OS version is neither 22 nor 24, skipping haproxy installation"
    exit 1
fi
systemctl kill haproxy >/dev/null 2>&1
systemctl stop haproxy >/dev/null 2>&1
systemctl disable haproxy >/dev/null 2>&1

ln -sf $(pwd)/hiddify-haproxy.service /etc/systemd/system/hiddify-haproxy.service
systemctl enable hiddify-haproxy.service
