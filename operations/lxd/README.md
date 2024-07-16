# Quick Setup (TL;DR)
Run the following commands:
`git clone `

# What is LXD?
LXD is used for managing LXC containers, the difference between Docker and LXC is that in Docker we containerize each application but LXC offers the whole operating system as one container.
Using the bash files in this folder, you will be able to set up an LXC container with Hiddify Manager inside it.

# Step 1: Installing LXD
First LXD must be installed. Our script `setup_lxc_container.sh` can install LXD on the following OSs:

* Ubuntu 24.04
* Debian 12
* Fedora 40
* AlmaLinux 9 and Rocky Linux 9

But if you don't use the distros above, you can still install LXD manually and keep using our scripts.

# Step 2: Setting up an Ubuntu 22.04 LXC container
After `setup_lxc_container.sh` installs LXD, it will automatically set up the container and install Hiddify Manager in it.
The ports 80 and 443 on your host OS must be available for binding, otherwise your Hiddify Manager installation won't have a valid SSL certificate.

# Step 3: Configuring Hiddify Manager
To configure your Hiddify Manager you can use the URLs that are printed after the container is set up. If you have lost those URLs or need to enter your container for any reason, you can do so by the command `lxc shell Hiddify-on-LXC`.

# Step 4: Bind the ports used by Hiddify Manager on your host OS.
After changing the configuration of your Hiddify Manager,unless no port used by Hiddify Mananger has changed, **you always need to run the following script**, which binds the appropriate ports from your container to your host OS.
`bash utils/lxc_ports_to_host.sh`. If you need to bind any other ports, you can first run `hiddify_ports_to_csv.sh`, then edit the CSV file it creates, and after that run the `lxc_ports_to_host.sh` script.
