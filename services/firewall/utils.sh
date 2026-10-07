#!/bin/bash
# Helpers only the firewall service uses (services/firewall/run.sh.j2).
# add2iptables*/allow_port/... add rules, redirect_domain_ports redirects the domains' own gateway ports,
# save_firewall makes the rules survive a reboot.

# False when the kernel has IPv6 off (ipv6.disable=1): ip6tables then only fails.
function has_ipv6(){
    [ -d /proc/sys/net/ipv6 ] && command -v ip6tables >/dev/null 2>&1
}

function add2iptables46(){
    add2iptables "$1"
    add2ip6tables "$1"
}

function add2iptables() {
    iptables -C $1 >/dev/null 2>&1 || echo "adding rule $1" && iptables -I $1

}

function add2ip6tables() {
    has_ipv6 || return 0
    ip6tables -C $1 >/dev/null 2>&1 || echo "adding rule $1" && ip6tables -I $1
}

function allow_port() { #allow_port "tcp" "80"
    add2iptables46 "INPUT -p $1 --dport $2 -j ACCEPT"
    
    # if [[ $1 == 'udp' ]]; then
    add2iptables46 "INPUT -p $1 -m $1 --dport $2 -m conntrack --ctstate NEW -j ACCEPT"
    # fi
}

function block_port() { #allow_port "tcp" "80"
    add2iptables46 "INPUT -p $1 --dport $2 -j DROP"
}

function remove_port() { #allow_port "tcp" "80"
    iptables -D INPUT -p "$1" --dport "$2" -j ACCEPT
    has_ipv6 && ip6tables -D INPUT -p "$1" --dport "$2" -j ACCEPT
}

function allow_apps_ports() {
    local service_name=$1

    # Get ports and paths for the service
    local ports=$(ss -tulpn | grep "$service_name" | awk '{print $5}' | cut -d':' -f2)
    local paths=$(pgrep -f "$service_name" | while read -r pid; do readlink -f /proc/"$pid"/exe; done | awk '!seen[$0]++')

    if [[ -z $ports ]]; then
        echo "Service $service_name not found or not running"
    else
        IFS=' ' read -ra portArray <<<"$ports"
        for p in "${portArray[@]}"; do
            for path in $paths; do
                echo "Service $service_name is running on port $p and path $path"
                allow_port "tcp" "$p"
            done
        done
    fi
}

# Domains with their own gateway ports (Domains page → Advanced): what arrives there is handed to the normal
# gateway ports, with the client's address intact. TLS ports (tcp and udp) go to 443, HTTP ports to 80.
# The chain is rebuilt each time, so ports that were changed or removed stop being redirected.
function redirect_domain_ports() { # redirect_domain_ports "9443 8443" "8080"
    local tool port chain=HIDDIFY_DOMAIN_PORTS
    for tool in iptables ip6tables; do
        [ "$tool" = ip6tables ] && ! has_ipv6 && continue
        {
            $tool -t nat -N $chain 2>/dev/null || $tool -t nat -F $chain
            $tool -t nat -C PREROUTING -j $chain 2>/dev/null || $tool -t nat -I PREROUTING -j $chain
            for port in $1; do
                $tool -t nat -A $chain -p tcp --dport "$port" -j REDIRECT --to-ports 443
                $tool -t nat -A $chain -p udp --dport "$port" -j REDIRECT --to-ports 443
            done
            for port in $2; do
                $tool -t nat -A $chain -p tcp --dport "$port" -j REDIRECT --to-ports 80
            done
        } || true # (ip6tables may have no nat table on some kernels)
    done
}

function save_firewall() {
    mkdir -p /etc/iptables/
    # Drop repeated rules, but keep every table's header and COMMIT (filter and nat have their own).
    iptables-save | awk '/^(\*|COMMIT)/ || !seen[$0]++' >/etc/iptables/rules.v4
    if has_ipv6; then
        ip6tables-save | awk '/^(\*|COMMIT)/ || !seen[$0]++' >/etc/iptables/rules.v6
        ip6tables-restore </etc/iptables/rules.v6
    fi
    iptables-restore </etc/iptables/rules.v4
}
