function set_env_if_empty(){
 for line in $(sed 's/\#.*//g' config.env | grep '=');do
  
  
  IFS=\= read k v <<< $line
  if [[ ! -z $k && -z "${!k}" ]]; then      
      export $k="$v"
  fi
  echo $k="$v"
 done        

}


function check_for_root(){
    if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
        exit 1
    fi

}

# Modify the SSH port number
function changeLinuxSSHPort(){
    green " Modify the port number for SSH login, do not use the commonly used port number. For example 20|21|23|25|53|69|80|110|443|123!"
    read -p "Please enter the port number to be modified (must be a pure number and between 1024~65535 or 22):" osSSHLoginPortInput
    osSSHLoginPortInput=${osSSHLoginPortInput:-0}

    if [ $osSSHLoginPortInput -eq 22 -o $osSSHLoginPortInput -gt 1024 -a $osSSHLoginPortInput -lt 65535 ]; then
        sed -i "s/#\?Port [0-9]*/Port $osSSHLoginPortInput/g" /etc/ssh/sshd_config

        if [ "$osRelease" == "centos" ] ; then

            if  [[ ${osReleaseVersionNoShort} == "7" ]]; then
                yum -y install policycoreutils-python
            elif  [[ ${osReleaseVersionNoShort} == "8" ]]; then
                yum -y install policycoreutils-python-utils
            fi

            # semanage port -l
            semanage port -a -t ssh_port_t -p tcp ${osSSHLoginPortInput}
            if command -v firewall-cmd &> /dev/null; then
                firewall-cmd --permanent --zone=public --add-port=$osSSHLoginPortInput/tcp 
                firewall-cmd --reload
            fi
    
            ${sudoCmd} systemctl restart sshd.service

        fi

        if [ "$osRelease" == "ubuntu" ] || [ "$osRelease" == "debian" ] ; then
            semanage port -a -t ssh_port_t -p tcp $osSSHLoginPortInput
            ${sudoCmd} ufw allow $osSSHLoginPortInput/tcp

            ${sudoCmd} service ssh restart
            ${sudoCmd} systemctl restart ssh
        fi

        green "The setting is successful, please remember the set port number ${osSSHLoginPortInput}!"
        green "login server command: ssh -p ${osSSHLoginPortInput} root@111.111.111.your ip !"
    else
        red "Wrong port number entered! Range : 22,1025~65534. Exit !"
    fi
}
