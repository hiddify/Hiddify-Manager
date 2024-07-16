#!/usr/bin/env bash

DIR_PATH=$(dirname "${BASH_SOURCE[0]}")/
LXC_CONTAINER_NAME="Hiddify-on-LXC"
INPUT_FILE="current.json"
OUTPUT_FILE="hiddify_service_ports_in_use.csv"
lxc exec $LXC_CONTAINER_NAME -- bash -c "cat /opt/hiddify-manager/current.json" > ${DIR_PATH}${INPUT_FILE}

# Store domain information in CSV
jq -r '
  .domains[] |
  .domain as $domain_name |
  if .internal_port_tuic != 0 then
    "\($domain_name),tuic,\(.internal_port_tuic)"
  else
    empty
  end,
  if .internal_port_hysteria2 != 0 then
    "\($domain_name),hysteria,\(.internal_port_hysteria2)"
  else
    empty
  end
' ${DIR_PATH}${INPUT_FILE} >> ${DIR_PATH}${OUTPUT_FILE}

# Append global ports to CSV
jq -r '
  .chconfigs[] |
  if .wireguard_enable then
    ",wireguard,\(.wireguard_port)"
  else
    empty
  end,
  if .ssh_server_enable then
    ",ssh_server,\(.ssh_server_port)"
  else
    empty
  end,
  ",tls,\(.tls_ports)",
  if .http_proxy_enable then
    ",http,\(.http_ports)"
  else
    empty
  end,
  if .kcp_enable then
    ",kcp,\(.kcp_ports)"
  else
    empty
  end,
  if .shadowsocks2022_enable then
    ",shadowsocks2022,\(.shadowsocks2022_port)"
  else
    empty
  end
' ${DIR_PATH}${INPUT_FILE} >> ${DIR_PATH}${OUTPUT_FILE}

rm ${DIR_PATH}${INPUT_FILE}

