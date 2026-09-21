#!/usr/bin/env bash

DIR_PATH=$(dirname "${BASH_SOURCE[0]}")/
MODE="advanced" # Set the mode (can be 'basic' or 'advanced')
LXC_CONTAINER_NAME="Hiddify-on-LXC"
CSV_FILE="hiddify_service_ports_in_use.csv"

set -e
if [ ! -f "${DIR_PATH}${CSV_FILE}" ]; then
    USER_CREATED_CSV="0"
    bash ${DIR_PATH}hiddify_ports_to_csv.sh
fi

# Remove all bound ports
fetch_services_from_csv() {
    NEW_DEVICE_QUEUE=()

    # Fill file descriptor 3 with csv file
    exec 3< "${DIR_PATH}${CSV_FILE}"

    while IFS="," read -u 3 -r PROTOCOL_DOMAIN PROTOCOL_NAME PROTOCOL_PORT ; do
	echo "$PROTOCOL_DOMAIN $PROTOCOL_NAME $PROTOCOL_PORT"
        if [[ "$MODE" == "advanced" ]]; then
            PROMPT_MESSAGE="What port would you prefer for \"${PROTOCOL_DOMAIN:+$PROTOCOL_DOMAIN }$PROTOCOL_NAME\" to be bound to the host machine? [default=$PROTOCOL_PORT]?"
            DEFAULT_PORT=$PROTOCOL_PORT
            read -p "$PROMPT_MESSAGE" -r USER_INPUT
            USER_PORT=${USER_INPUT:-$DEFAULT_PORT}
        else
	    USER_PORT=$PROTOCOL_PORT
        fi

        # Detect TCP/UDP
        PROTOCOL="tcp"
        if [[ "$PROTOCOL_NAME" == "hysteria" || "$PROTOCOL_NAME" == "tuic" || "$PROTOCOL_DOMAIN" == "wireguard" ]]; then
    	PROTOCOL="udp"	
        fi
    
        NEW_DEVICE_QUEUE+=("lxc config device add $LXC_CONTAINER_NAME ${PROTOCOL_DOMAIN:+$PROTOCOL_DOMAIN_}${PROTOCOL_NAME} proxy listen=$PROTOCOL:0.0.0.0:$USER_PORT connect=$PROTOCOL:127.0.0.1:$PROTOCOL_PORT")
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

