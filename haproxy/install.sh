source ../common/utils.sh
rm -rf *.template
if is_installed sniproxy; then
    # systemctl kill hiddify-sniproxy > /dev/null 2>&1
    systemctl stop hiddify-sniproxy >/dev/null 2>&1
    systemctl disable hiddify-sniproxy >/dev/null 2>&1
    pkill -9 sniproxy >/dev/null 2>&1
fi

HAPROXY_VERSION=3.4
if ! is_installed_package "haproxy-awslc"; then
    CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
    REPO_TAG="ha${HAPROXY_VERSION//./}"

    echo "Adding HAProxy repo for ${CODENAME} (haproxy-${HAPROXY_VERSION})"
    install -d -m 0755 /usr/share/keyrings
    wget -qO /usr/share/keyrings/HAPROXY-key-community.asc https://pks.haproxy.com/linux/community/RPM-GPG-KEY-HAProxy
    echo "deb [signed-by=/usr/share/keyrings/HAPROXY-key-community.asc] https://www.haproxy.com/download/haproxy/performance/ubuntu/${REPO_TAG} ${CODENAME} main" >/etc/apt/sources.list.d/haproxy.list
    apt-get update -qq
    echo "Installing haproxy ${HAPROXY_VERSION}"
    install_package "haproxy-awslc"
else
    echo "haproxy ${HAPROXY_VERSION} is already installed"
fi
systemctl kill haproxy >/dev/null 2>&1
systemctl stop haproxy >/dev/null 2>&1
systemctl disable haproxy >/dev/null 2>&1

ln -sf $(pwd)/hiddify-haproxy.service /etc/systemd/system/hiddify-haproxy.service
systemctl enable hiddify-haproxy.service