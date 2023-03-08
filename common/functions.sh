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