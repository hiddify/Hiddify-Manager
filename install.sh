#!/bin/bash
echo "we are going to install :)"
export DEBIAN_FRONTEND=noninteractive
if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
#        exit 1
fi



function set_env_if_empty(){
 echo "applying configs from $1========================================="
 for line in $(sed 's/\#.*//g' $1 | grep '=');do  
  IFS=\= read k v <<< $line
#   if [[ ! -z $k && -z "${!k}" ]]; then      
      export $k="$v"
      echo $k="$v"
#   fi
  
 done        

}

function check_req(){
        
   for req in hexdump dig curl git;do
        which $req
        if [[ "$?" != 0 ]];then
                apt update
                apt install -y dnsutils bsdmainutils curl git
                break
        fi
   done
   
}

function runsh() {    
        pushd $2; 
        if [[ -f $1 ]];then
                echo "==========================================================="
                echo "===$1 $2"
                echo "==========================================================="        
                bash $1
        fi
        popd 
}

function do_for_all() {
        #cd /opt/$GITHUB_REPOSITORY
        bash common/replace_variables.sh
        runsh $1.sh common
        runsh $1.sh ssl
        runsh $1.sh nginx
        runsh $1.sh sniproxy
        runsh $1.sh xray
        runsh $1.sh web
        if [[ $ENABLE_TELEGRAM == true ]]; then
                runsh $1.sh telegram
        else
                runsh uninstall.sh telegram
        fi
        if [[ $ENABLE_SS == true ]]; then
                runsh $1.sh shadowsocks
        else
                runsh uninstall.sh shadowsocks
        fi
        if [[ $ENABLE_VMESS == true ]]; then
                runsh $1.sh deprecated/vmess
        else
                runsh uninstall.sh deprecated/vmess
        fi

        if [[ $ENABLE_MONITORING == true ]]; then
                runsh $1.sh deprecated/monitoring
        else
                runsh uninstall.sh deprecated/monitoring
        fi

        if [[ $ENABLE_NETDATA == true ]]; then
                runsh $1.sh netdata
        else
                runsh uninstall.sh netdata
        fi

        if [[ $ENABLE_TROJAN_GO == true ]]; then
                runsh $1.sh deprecated/trojan-go
        else
                runsh uninstall.sh deprecated/trojan-go
        fi
        
        runsh $1.sh admin_ui
}


function check_for_env() {

        random_secret=$(hexdump -vn16 -e'4/4 "%08x" 1 "\n"' /dev/urandom)
        replace_empty_env USER_SECRET "setting 32 char user secret" $random_secret "^([0-9A-Fa-f]{32})$"

        random_path=$(tr -dc A-Za-z0-9 </dev/urandom | head -c $(shuf -i 10-32 -n 1))
        replace_empty_env BASE_PROXY_PATH "setting proxy path" $random_secret ".*"
        
        random_tel_secret=$(hexdump -vn16 -e'4/4 "%08x" 1 "\n"' /dev/urandom)
        replace_empty_env TELEGRAM_USER_SECRET "setting 32 char for TELEGRAM_USER_SECRET" $random_tel_secret ".*"

        random_admin_secret=$(hexdump -vn16 -e'4/4 "%08x" 1 "\n"' /dev/urandom)
        replace_empty_env ADMIN_SECRET "setting 32 char admin secret" $random_admin_secret "^([0-9A-Fa-f]{32})$"

        

        export SERVER_IP=$(curl -Lso- https://api.ipify.org)
        replace_empty_env MAIN_DOMAIN "please enter valid domain name to use " "$SERVER_IP.nip.io" "^([A-Za-z0-9\.]+\.[a-zA-Z]{2,})$"
        
        
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
                        echo "Enter $VAR?"
                else
                        # echo "Enter $VAR (default value='$DEFAULT' -> to confirm enter)"
                        echo "using '$DEFAULT' for $VAR"
                fi

                # read -p "> " RESPONSE
                #if [[ -z "$RESPONSE" ]]; then
                #        RESPONSE=$DEFAULT
                #fi
                RESPONSE=$DEFAULT
                if [[ ! -z "$REGEX" ]];then
                        if [[ "$RESPONSE" =~ $REGEX ]];then
                                sed -i "s|$1=|$1=$RESPONSE|g" config.env 
                                cat config.env|grep -e "^$1"
                                if [[ "$!?" != "0" ]]; then
                                    echo "$1=$RESPONSE">> config.env
                                fi

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

function main(){
        check_req
        set_env_if_empty config.env.default
        set_env_if_empty config.env      
        if [[ "$BASE_PROXY_PATH" == "" ]]; then
                replace_empty_env BASE_PROXY_PATH "" $USER_SECRET ".*"
        fi
        if [[ "$TELEGRAM_USER_SECRET" == "" ]]; then
                replace_empty_env TELEGRAM_USER_SECRET "" $USER_SECRET ".*"
        fi

        cd /opt/$GITHUB_REPOSITORY
        git pull

        if [[ "$FIRST_SETUP" == "" ]];then
                replace_empty_env FIRST_SETUP "First Setup Detected!" false ".*"
                export FIRST_SETUP="true"
        fi

        if [[ -z "$DO_NOT_RUN" || "$DO_NOT_RUN" == false ]];then
                check_for_env
        fi

        if [[ -z "$DO_NOT_INSTALL" || "$DO_NOT_INSTALL" == false  ]];then
                do_for_all install
                systemctl daemon-reload
        fi

        if [[ -z "$DO_NOT_RUN" || "$DO_NOT_RUN" == false ]];then
                do_for_all run
                
                echo ""
                echo ""
                echo "==========================================================="
                echo "Finished! Thank you for helping Iranians to skip filternet."
                echo "Please open the following link in the browser for client setup"
                bash status.sh
                cat use-link
        fi
        systemctl restart hiddify-admin.service
}

mkdir -p log/system/
main |& tee log/system/0-install.log
