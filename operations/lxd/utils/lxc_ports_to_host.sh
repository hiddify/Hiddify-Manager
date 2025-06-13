#!/usr/bin/env bash

DIR_PATH=$(dirname "${BASH_SOURCE[0]}")/
MODE="advanced" # Set the mode (can be 'basic' or 'advanced')
LXC_CONTAINER_NAME="Hiddify-on-LXC"
CSV_FILE="hiddify_service_ports_in_use.csv"
LISTEN_ADDRESS="0.0.0.0"  # Default listen address
INTERACTIVE=true

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -i, --interface <interface>  Specify network interface to use"
    echo "  -a, --address <ip>          Specify custom IP address to use"
    echo "  -n, --non-interactive       Use defaults (0.0.0.0) without prompts"
    echo "  -h, --help                  Show this help message"
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interface)
            if [[ -n "$2" ]]; then
                LISTEN_ADDRESS=$(ip -o -4 addr show "$2" 2>/dev/null | awk '{print $4}' | cut -d'/' -f1)
                if [[ -z "$LISTEN_ADDRESS" ]]; then
                    echo "Error: Invalid interface or no IPv4 address found for interface $2"
                    exit 1
                fi
                MODE="basic"
                INTERACTIVE=false
            else
                echo "Error: Interface name required"
                exit 1
            fi
            shift 2
            ;;
        -a|--address)
            if [[ -n "$2" ]]; then
                LISTEN_ADDRESS="$2"
                MODE="basic"
                INTERACTIVE=false
            else
                echo "Error: IP address required"
                exit 1
            fi
            shift 2
            ;;
        -n|--non-interactive)
            INTERACTIVE=false
            MODE="basic"
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Function to get available network interfaces
get_network_interfaces() {
    echo "Available network interfaces:"
    echo "0) 0.0.0.0 (Listen on all interfaces)"
    local i=1
    while IFS= read -r line; do
        if [[ $line =~ ^[0-9]+:\ ([^:@]+):.*$ ]]; then
            local iface="${BASH_REMATCH[1]}"
            local ip=$(ip -o -4 addr show "$iface" 2>/dev/null | awk '{print $4}' | cut -d'/' -f1)
            if [ -n "$ip" ]; then
                echo "$i) $iface ($ip)"
            fi
        ((i++))
        fi
    done < <(ip link show)
}

# Function to select binding mode
select_binding_mode() {
    echo "Please select port binding mode:"
    echo "1) Listen on all interfaces (0.0.0.0)"
    echo "2) Select specific interface/IP"
    echo "3) Configure each port individually"
    read -p "Enter your choice (1-3): " choice

    case $choice in
        1)
            LISTEN_ADDRESS="0.0.0.0"
            MODE="basic"
            ;;
        2)
            get_network_interfaces
            read -p "Enter the number of your choice: " interface_choice
            if [ "$interface_choice" = "0" ]; then
                LISTEN_ADDRESS="0.0.0.0"
            else
                local i=1
                while IFS= read -r line; do
                    if [[ $line =~ ^[0-9]+:\ ([^:@]+):.*$ ]]; then
                        local iface="${BASH_REMATCH[1]}"
                        if [ "$i" = "$interface_choice" ]; then
                            LISTEN_ADDRESS=$(ip -o -4 addr show "$iface" 2>/dev/null | awk '{print $4}' | cut -d'/' -f1)
                            break
                        fi
                        ((i++))
                    fi
                done < <(ip link show)
            fi
            MODE="basic"
            ;;
        3)
            MODE="advanced"
            ;;
        *)
            echo "Invalid choice. Using default (0.0.0.0)"
            LISTEN_ADDRESS="0.0.0.0"
            MODE="basic"
            ;;
    esac
}

set -e
if [ ! -f "${DIR_PATH}${CSV_FILE}" ]; then
    USER_CREATED_CSV="0"
    bash ${DIR_PATH}hiddify_ports_to_csv.sh
fi

# Only show binding mode selection if in interactive mode
if [[ "$INTERACTIVE" == "true" ]]; then
    select_binding_mode
fi

# Remove all bound ports
fetch_services_from_csv() {
    NEW_DEVICE_QUEUE=()

    # Fill file descriptor 3 with csv file
    exec 3< "${DIR_PATH}${CSV_FILE}"

    # Track used device names
    declare -A USED_DEVICE_NAMES

    while IFS="," read -u 3 -r PROTOCOL_DOMAIN PROTOCOL_NAME PROTOCOL_PORT ; do
        current_listen=$LISTEN_ADDRESS
        USER_PORT=$PROTOCOL_PORT

        if [[ "$MODE" == "advanced" && "$INTERACTIVE" == "true" ]]; then
            echo "Configuration for ${PROTOCOL_DOMAIN:+$PROTOCOL_DOMAIN }$PROTOCOL_NAME (Port: $PROTOCOL_PORT)"
            get_network_interfaces
            read -p "Select interface number: " interface_choice
            if [ "$interface_choice" = "0" ]; then
                current_listen="0.0.0.0"
            else
                local i=1
                while IFS= read -r line; do
                    if [[ $line =~ ^[0-9]+:\ ([^:@]+):.*$ ]]; then
                        local iface="${BASH_REMATCH[1]}"
                        if [ "$i" = "$interface_choice" ]; then
                            current_listen=$(ip -o -4 addr show "$iface" 2>/dev/null | awk '{print $4}' | cut -d'/' -f1)
                            break
                        fi
                        ((i++))
                    fi
                done < <(ip link show)
            fi
            
            read -p "What port would you prefer? [default=$PROTOCOL_PORT]: " -r USER_INPUT
            USER_PORT=${USER_INPUT:-$PROTOCOL_PORT}
        fi

        # Detect TCP/UDP
        PROTOCOL="tcp"
        if [[ "$PROTOCOL_NAME" == "hysteria" || "$PROTOCOL_NAME" == "tuic" || "$PROTOCOL_NAME" == "wireguard" ]]; then
            PROTOCOL="udp"   
        fi

        # Compose device name and ensure uniqueness
        DEVICE_NAME="${PROTOCOL_DOMAIN:+${PROTOCOL_DOMAIN}_}${PROTOCOL_NAME}"
        if [[ -n "${USED_DEVICE_NAMES[$DEVICE_NAME]}" ]]; then
            DEVICE_NAME="${DEVICE_NAME}_"
        fi
        USED_DEVICE_NAMES["$DEVICE_NAME"]=1

        NEW_DEVICE_QUEUE+=("lxc config device add $LXC_CONTAINER_NAME $DEVICE_NAME proxy listen=$PROTOCOL:$current_listen:$USER_PORT connect=$PROTOCOL:127.0.0.1:$PROTOCOL_PORT")
    done
}

remove_old_services() {
    for i in $(lxc config device list $LXC_CONTAINER_NAME); do
         lxc config device remove $LXC_CONTAINER_NAME "$i"	
    done
}
add_new_services() {
    for job in "${NEW_DEVICE_QUEUE[@]}"; do
         eval "$job"
    done
}


fetch_services_from_csv
trap '' SIGINT		# Prevent user from cancelling the script
remove_old_services
add_new_services

# Remove CSV file if it's not created by the user.
if [ "$USER_CREATED_CSV" == "0" ]; then
    rm ${DIR_PATH}${CSV_FILE}
fi

