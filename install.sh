#!/bin/sh
echo "we are going to install :)"

if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
#        exit 1
fi



function set_env_if_empty(){
 for line in $(sed 's/\#.*//g' config.env | grep '=');do
  
  
  IFS=\= read k v <<< $line
  if [[ ! -z $k && -z "${!k}" ]]; then      
      export $k="$v"
  fi
  echo $k="$v"
 done        

}

function runsh() {    
        pushd $2; 
        if [[ -f $1 ]];then
                echo "==========================================================="
                echo "===$1 $2"
                echo "==========================================================="        
                bash $1; 
        fi
        popd 
}

function do_for_all() {
        #cd /opt/$GITHUB_REPOSITORY
        bash common/replace_variables.sh
        runsh $1.sh common
        runsh $1.sh nginx
        if [[ $ENABLE_TELEGRAM == true ]]; then
                runsh $1.sh telegram
        fi
        if [[ $ENABLE_SS == true ]]; then
                runsh $1.sh shadowsocks
        fi
        if [[ $ENABLE_VMESS == true ]]; then
                runsh $1.sh vmess
        fi
}


function check_for_env() {

        random_secret=$(hexdump -vn16 -e'4/4 "%08X" 1 "\n"' /dev/urandom)
        replace_empty_env USER_SECRET "please enter 32 char user secret" $random_secret "^([0-9A-Fa-f]{32})$"
        replace_empty_env MAIN_DOMAIN "please enter valid domain name to use " "www.example.com" "^([A-Za-z0-9\.]+\.[a-zA-Z]{2,})$"
        DOMAIN_IP=$(dig +short -t a $MAIN_DOMAIN.)
        SERVER_IP=$(curl -Lso- https://api.ipify.org)

        echo "resolving domain $MAIN_DOMAIN -> IP= $DOMAIN_IP ServerIP-> $SERVER_IP"
        if [[ $SERVER_IP != $DOMAIN_IP ]];then
                echo "maybe it is an error! make sure that it is correct"
                sleep 5
        fi

        # replace_empty_env CLOUD_PROVIDER "If you are using a cdn please enter the cdn domain " "" /^([a-z0-9\.]+\.[a-z]{2,})?$/i

}

function replace_empty_env() {
        VAR=$1
        DESCRIPTION=$2
        DEFAULT=$3
        REGEX=$4
        if [[ -z "${!VAR}" ]]; then
                echo ''
                echo "============================"
                echo "$DESCRIPTION"
                
                if [[ -z "$DEFAULT" ]]; then
                        echo "Enter $DEFAULT?"
                else
                        echo "Enter $DEFAULT (default value='$DEFAULT' -> to confirm enter)"
                fi

                read -p "> " RESPONSE
                if [[ -z "$RESPONSE" ]]; then
                        RESPONSE=$DEFAULT
                fi
                
                if [[ ! -z "$REGEX" ]];then
                        if [[ "$RESPONSE" =~ $REGEX ]];then
                                sed -i "s|$1=|$1=$RESPONSE|g" config.env 
                                export $1=$RESPONSE
                        else 
                                echo "!!!!!!!!!!!!!!!!!!!!!!"
                                echo "invalid response $RESPONSE -> regex= $REGEX"
                                echo "retry:"
                                replace_empty_env "$1" "$2" "$3" "$4"
                        fi

                fi
                
        fi
}



set_env_if_empty

cd /opt/$GITHUB_REPOSITORY

if [[ -z "$DO_NOT_RUN" || "$DO_NOT_RUN" == false ]];then
        check_for_env
fi

if [[ -z "$DO_NOT_INSTALL" || "$DO_NOT_INSTALL" == false  ]];then
        do_for_all install
fi

if [[ -z "$DO_NOT_RUN" || "$DO_NOT_RUN" == false ]];then
        do_for_all run
        echo ""
        echo ""
        echo "==========================================================="
        echo "Thank you for helping Iranians to skip filternet."
        echo "Please open the following link in the browser for client setup"
        cat nginx/use-link
fi

