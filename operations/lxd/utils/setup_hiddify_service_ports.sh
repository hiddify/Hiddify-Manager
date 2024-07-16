#!/bin/bash

bash fetch_hiddify_service_ports.sh

MODE="advanced" # Set the mode (can be 'basic' or 'advanced')
LXC_CONTAINER_NAME="Hiddify-on-LXC"
INPUT_FILE="hiddify_service_ports_in_use.csv"

for line in $(cat $INPUT_FILE); do
    IFS=',' read -r FIRST_COL SECOND_COL THIRD_COL <<< "$line"

    if [[ "$MODE" == "advanced" ]]; then
        if [[ -n "$THIRD_COL" ]]; then
            PROMPT_MESSAGE="What port would you prefer for \"$FIRST_COL $SECOND_COL\" to be bind to the host machine? [default=$THIRD_COL]?"
            DEFAULT_PORT=$THIRD_COL
        else
            PROMPT_MESSAGE="What port would you prefer for \"$FIRST_COL\" to be bind to the host machine? [default=$SECOND_COL]?"
            DEFAULT_PORT=$SECOND_COL
        fi

        read -p "$PROMPT_MESSAGE " USER_INPUT
        USER_PORT=${USER_INPUT:-$DEFAULT_PORT}
    else
    	if [[ -n "$THIRD_COL" ]]; then
        	USER_PORT=$THIRD_COL
	    else
		USER_PORT=$SECOND_COL
	    fi
    fi

    # Diagnosis protocol TCP/UDP
    PROTOCOL="tcp"
    if [[ -n "$THIRD_COL" ]]; then
	    if [[ "$SECOND_COL" == "hysteria" || "$SECOND_COL" == "tuic" ]]; then
		PROTOCOL="udp"	
	    fi
    else
	    if [[ "$FIRST_COL" == "wireguard" || "$FIRST_COL" == "hysteria" ]]; then
		PROTOCOL="udp"	
	    fi
    fi

    # Remove all bounded ports
    for i in $(lxc config device list $LXC_CONTAINER_NAME); do
	lxc config device remove $LXC_CONTAINER_NAME $i	
    done

    # Add new binding rules
    if [[ -n "$THIRD_COL" ]]; then
        lxc config device add $LXC_CONTAINER_NAME $FIRST_COL proxy listen=$PROTOCOL:0.0.0.0:$USER_PORT connect=tcp:127.0.0.1:$THIRD_COL
    else
        lxc config device add $LXC_CONTAINER_NAME $FIRST_COL proxy listen=$PROTOCOL:0.0.0.0:$USER_PORT connect=tcp:127.0.0.1:$SECOND_COL
    fi
done
