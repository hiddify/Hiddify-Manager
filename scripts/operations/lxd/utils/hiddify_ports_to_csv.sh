#!/usr/bin/env bash

DIR_PATH=$(dirname "${BASH_SOURCE[0]}")/
LXC_CONTAINER_NAME="Hiddify-on-LXC"
INPUT_FILE="current.json"
OUTPUT_FILE="hiddify_service_ports_in_use.csv"
lxc exec $LXC_CONTAINER_NAME -- bash -c "cat /opt/hiddify-manager/data/current.json" > ${DIR_PATH}${INPUT_FILE}

# The panel's public ports (gateway, services and custom proxies), the same list the firewall opens: ",<name> (<proto>),<port>"
jq -r '
  .public_ports // {} | to_entries[] | .key as $proto | (.value // {}) | to_entries[] |
  ",\(.value) (\($proto)),\(.key)"
' ${DIR_PATH}${INPUT_FILE} >> ${DIR_PATH}${OUTPUT_FILE}

rm ${DIR_PATH}${INPUT_FILE}

