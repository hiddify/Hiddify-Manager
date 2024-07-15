#!/bin/bash

DEBUG=0
LXC_CONTAINER_NAME="Hiddify-on-LXC"
LXC_IMAGE="ubuntu:22.04"

# You may change any of the variables below, to change the port bound on your public/host IP.
HTTP_PORT_ON_HOST=80
HTTPS_PORT_ON_HOST=443

if [ $DEBUG -eq 1 ]; then
  set -e
fi

# Install lxd based on the OS
install_lxd() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      debian)
        echo "Debian detected!"
	export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y lxd
        ;;
      ubuntu)
        echo "Ubuntu detected!"
	export DEBIAN_FRONTEND=noninteractive
	snap install lxd
	snap refresh lxd
	;;
      fedora)
        echo "Fedora detected!"
        dnf install -y lxd
        ;;
      almalinux|rocky)
        echo "AlmaLinux/Rocky detected!"
        dnf install -y snapd
        ln -s /var/lib/snapd/snap /snap
        snap install lxd
        ;;
      *)
        echo "Unsupported OS for LXD installation: $ID"
	echo "Please install LXD manually and run the script again."
        exit 1
        ;;
    esac
  else
    echo "Unable to detect OS."
    echo "Please install LXD manually and run the script again."
    exit 1
  fi
}

# Fetch an Ubuntu 22.04 image and create a container
setup_container() {
  # Check if the container already exists
  if ! lxc info $LXC_CONTAINER_NAME &> /dev/null; then
    lxc init $LXC_IMAGE $LXC_CONTAINER_NAME
    lxc start $LXC_CONTAINER_NAME
  
    # Set up port forwarding
    lxc config device add $LXC_CONTAINER_NAME http 	proxy 	listen=tcp:0.0.0.0:$HTTP_PORT_ON_HOST connect=tcp:127.0.0.1:80
    lxc config device add $LXC_CONTAINER_NAME https 	proxy 	listen=tcp:0.0.0.0:$HTTPS_PORT_ON_HOST connect=tcp:127.0.0.1:443
    lxc config device add $LXC_CONTAINER_NAME httpsudp 	proxy 	listen=udp:0.0.0.0:$HTTPS_PORT_ON_HOST connect=udp:127.0.0.1:443
   
    # Install necessary packages and run the setup script in the container
    lxc exec $LXC_CONTAINER_NAME -- apt-get update
    lxc exec $LXC_CONTAINER_NAME -- apt-get install -y apt-transport-https ca-certificates curl wget gnupg-agent software-properties-common git jq
  
    if [ $DEBUG -eq 1 ]; then
      lxc exec $LXC_CONTAINER_NAME -- bash -x -c "cd /opt && export CREATE_EASYSETUP_LINK='true'; sleep 5; curl i.hiddify.com/release|bash -x -s -- --no-gui; exit 0"
    else
      lxc exec $LXC_CONTAINER_NAME -- bash -c "cd /opt && export CREATE_EASYSETUP_LINK='true'; sleep 5;curl i.hiddify.com/release|bash -s -- --no-gui; exit 0"
    fi
  else
    echo "Container $LXC_CONTAINER_NAME already exists. If you want to delete a previously made container use the command below:"
    echo "lxc delete $LXC_CONTAINER_NAME --force" 
    exit 1
  fi
}

# Check if the container is running
verify_container() {
  if lxc info $LXC_CONTAINER_NAME | grep -q 'Status: RUNNING'; then
    echo "Container $LXC_CONTAINER_NAME is up and running."
  else
    echo "Failed to start container $LXC_CONTAINER_NAME."
    exit 1
  fi
}


# Main script execution

# Check the user 
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root."
  exit 1
fi

if ! which lxd &> /dev/null; then
  echo "LXD not installed. I will install LXD..."
  install_lxd 
else
  echo "LXD already installed proceeding..."
fi

if lxd init --dump | grep "networks: \[\]" &> /dev/null; then
  echo "Initializing LXD minimally..."
  lxd init --minimal
else
  echo "LXD seems to be already initialized."
fi

setup_container
verify_container
