#!/bin/bash

# Modify the SSH port number
#function changeLinuxSSHPort(){
    green " Modify the port number for SSH login"

    if [ $SSH_PORT -eq 22 -o $SSH_PORT -gt 1024 -a $SSH_PORT -lt 65535 ]; then
        sed -i "s/#\?Port [0-9]*/Port $SSH_PORT/g" /etc/ssh/sshd_config

        if [ "$osRelease" == "centos" ] ; then

            if  [[ ${osReleaseVersionNoShort} == "7" ]]; then
                yum -y install policycoreutils-python
            elif  [[ ${osReleaseVersionNoShort} == "8" ]]; then
                yum -y install policycoreutils-python-utils
            fi

            # semanage port -l
            semanage port -a -t ssh_port_t -p tcp ${SSH_PORT}
            if command -v firewall-cmd &> /dev/null; then
                firewall-cmd --permanent --zone=public --add-port=$SSH_PORT/tcp 
                firewall-cmd --reload
            fi
    
            ${sudoCmd} systemctl restart sshd.service

        fi

        if [ "$osRelease" == "ubuntu" ] || [ "$osRelease" == "debian" ] ; then
            semanage port -a -t ssh_port_t -p tcp $SSH_PORT
            ${sudoCmd} ufw allow $SSH_PORT/tcp

            ${sudoCmd} service ssh restart
            ${sudoCmd} systemctl restart ssh
        fi

        green "The setting is successful, please remember the set port number ${SSH_PORT}!"
        green "login server command: ssh -p ${SSH_PORT} root@111.111.111.your ip !"
    else
        red "Wrong port number entered! Range : 22,1025~65534. Exit !"
    fi
#}