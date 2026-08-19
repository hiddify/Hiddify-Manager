
SERVER_WG_NIC=hiddifywg

add_number_to_ipv4() {
    local ip="$1"
    local number="$2"

    # Use awk to split the IP address into octets
    IFS='.' read -r -a octets <<<"$ip"

    # Increment the last octet by the specified number

    octets[2]=$(((${octets[2]} + (${octets[3]} + number) / 256)))
    octets[3]=$(((${octets[3]} + number) % 256))

    # Join the octets back together with dots and return
    echo "${octets[0]}.${octets[1]}.${octets[2]}.$((octets[3]))"
}

add_number_to_ipv6() {
    local ip="$1"
    local number="$2"

    # Use awk to split the IPv6 address into segments
    IFS=':' read -r -a segments <<<"$ip"

    # Increment the last segment by the specified number
    segments[${#segments[@]} - 1]=$((0x${segments[${#segments[@]} - 1]} + number))

    # Join the segments back together with colons and return
    local modified_ipv6=$(
        IFS=:
        echo "${segments[*]}"
    )
    echo "$modified_ipv6"
}
