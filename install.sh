
function set_env_if_empty(){
 for line in $(grep -v '^#' config.env | grep '=');do
  IFS=\= read k v <<< $line
  if [[ -z "${!k}" ]]; then      
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
        cd /opt/$GITHUB_REPOSITORY
        if [[ "$1" == "run" ]];then
                check_for_env
        fi
        bash replace_variables.sh
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
        replace_empty_env USER_SECRET "please enter 32 char user secret" $random_secret "/^([0-9A-F]{32})$/i"
        replace_empty_env DOMAIN "please enter valid domain name to use " "www.example.com" "/^([a-z0-9\.]+\.[a-z]{2,})$/i"
        echo "resolving domain $DOMAIN -> IP= $(dig +short -t $DOMAIN.) ServerIP-> $(curl -Lso- https://api.ipify.org)"



        # replace_empty_env CLOUD_PROVIDER "If you are using a cdn please enter the cdn domain " "" /^([a-z0-9\.]+\.[a-z]{2,})?$/i

}

function replace_empty_env() {
        VAR=$1
        DESCRIPTION=$2
        DEFAULT=$3
        REGEX=$4
        if [[ -z "${$VAR}" ]]; then
                
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
                if [[ -z "$REGEX" ]];then
                        if [[ "$RESPONSE" =~ $REGEX ]];then
                                sed -i "s|$1=|$1=$RESPONSE|g" config.env 
                        else 
                                echo "invalid response -> regex= $REGEX"
                                echo "retry:"
                                replace_empty_env $1 $2 $3 $4
                        fi

                fi
                
        fi
        source config.env
}


if [ ! -d "/opt/$GITHUB_REPOSITORY" ];then
        apt update
        apt install -y git
        git clone https://github.com/$GITHUB_USER/$GITHUB_REPOSITORY/  /opt/$GITHUB_REPOSITORY
        git checkout $GITHUB_BRANCH_OR_TAG
fi 

set_env_if_empty()

if [[ -z "$DO_NOT_INSTALL" || "$DO_NOT_INSTALL" == false  ]];then
        do_for_all install
fi

if [[ -z "$DO_NOT_RUN" || "$DO_NOT_RUN" == false ]];then
        do_for_all run
fi
