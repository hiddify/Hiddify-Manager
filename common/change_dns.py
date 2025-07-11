#!/opt/hiddify-manager/.venv313/bin/python
import os
import sys
import yaml

# Check if the script is run with sudo privileges
if os.geteuid() != 0:
    print("Please run this script with sudo or as root.")
    sys.exit(1)

# Check for the correct number of arguments
if len(sys.argv) != 3:
    print("Usage: {} <dns_server_1> <dns_server_2>".format(sys.argv[0]))
    sys.exit(1)

dns_server_1 = sys.argv[1]
dns_server_2 = sys.argv[2]

# Function to update DNS settings in a Netplan configuration file


def update_dns_settings(config_file):
    with open(config_file, 'r') as f:
        data = yaml.safe_load(f)
    os.system(f'chmod 600 {config_file}')
    for interface, config in data['network'].get('ethernets', {}).items():
        if config.get('dhcp4', False):
            # DHCP configuration
            if 'nameservers' not in config:
                config['nameservers'] = {}
            config['nameservers']['addresses'] = [dns_server_1, dns_server_2]
        elif 'addresses' in config:
            # Static IP configuration
            if 'nameservers' not in config:
                config['nameservers'] = {}
            config['nameservers']['addresses'] = [dns_server_1, dns_server_2]
        else:
            print("WTF")
    with open(config_file, 'w') as f:
        yaml.dump(data, f)
    print("DNS", data)
    print("DNS servers updated in", config_file)


def process_netplan_directory(directory):
    if not os.path.exists(directory):
        print(f"Directory {directory} does not exist")
        return
    for config_file in os.listdir(directory):
        config_file_path = os.path.join(directory, config_file)
        if config_file_path.endswith('.yaml') or config_file_path.endswith('.yml'):
            update_dns_settings(config_file_path)


# Iterate through all Netplan configurations
process_netplan_directory('/etc/netplan')
process_netplan_directory('/run/netplan')

# Apply the changes
os.system('netplan apply')

# Restart systemd-resolved to apply changes
os.system('systemctl start systemd-resolved')

print(f"DNS servers set to {dns_server_1} and {dns_server_2}")
