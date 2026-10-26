source /opt/hiddify-manager/scripts/common/utils.sh
rm -rf *.template
if is_installed sniproxy; then
    # systemctl kill hiddify-sniproxy > /dev/null 2>&1
    systemctl stop hiddify-sniproxy >/dev/null 2>&1
    systemctl disable hiddify-sniproxy >/dev/null 2>&1
    pkill -9 sniproxy >/dev/null 2>&1
fi

# Series 3.4 from haproxy.com (AWS-LC). Need >= 3.4.6 for the mux_quic RESET_STREAM
# crash fix (#5576 / upstream #3505); pin the floor to the current patch in that series.
HAPROXY_SERIES=3.4
HAPROXY_MIN_VERSION=3.4.7
installed_ver=$(dpkg-query -W -f='${Version}' haproxy-awslc 2>/dev/null || true)
need_install=0
if [ -z "$installed_ver" ]; then
    need_install=1
elif ! dpkg --compare-versions "$installed_ver" ge "$HAPROXY_MIN_VERSION"; then
    echo "haproxy-awslc $installed_ver is below $HAPROXY_MIN_VERSION (QUIC crash fix); upgrading"
    need_install=1
fi

if [ "$need_install" = 1 ]; then
    CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
    REPO_TAG="ha${HAPROXY_SERIES//./}"

    echo "Adding HAProxy repo for ${CODENAME} (haproxy-${HAPROXY_SERIES})"
    install -d -m 0755 /usr/share/keyrings
    wget -qO /usr/share/keyrings/HAPROXY-key-community.asc https://pks.haproxy.com/linux/community/RPM-GPG-KEY-HAProxy
    echo "deb [signed-by=/usr/share/keyrings/HAPROXY-key-community.asc] https://www.haproxy.com/download/haproxy/performance/ubuntu/${REPO_TAG} ${CODENAME} main" >/etc/apt/sources.list.d/haproxy.list
    apt-get update -qq
    echo "Installing haproxy-awslc (>= ${HAPROXY_MIN_VERSION})"
    install_package "haproxy-awslc"
else
    echo "haproxy-awslc $installed_ver is already installed (>= ${HAPROXY_MIN_VERSION})"
fi
systemctl kill haproxy >/dev/null 2>&1
systemctl stop haproxy >/dev/null 2>&1
systemctl disable haproxy >/dev/null 2>&1

ln -sf $(pwd)/hiddify-haproxy.service /etc/systemd/system/hiddify-haproxy.service
systemctl enable hiddify-haproxy.service