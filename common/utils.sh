export venv_path="/opt/hiddify-manager/.venv313"

function get_commit_version() {
    json_data=$(curl -sL -H "Accept: application/json" "https://github.com/hiddify/$1/commits/main.atom")
    latest_commit_date=$(echo "$json_data" | jq -r '.payload.commitGroups[0].commits[0].committedDate')
    # xml_data=$(curl -sl "https://github.com/hiddify/$1/commits/main.atom")
    # latest_commit_date=$(echo "$xml_data" | grep -m 1 '<updated>' | awk -F'>|<' '{print $3}')
    # COMMIT_URL=$(curl -s https://api.github.com/repos/hiddify/$1/git/refs/heads/main | jq -r .object.url)
    # latest_commit_date=$(curl -s $COMMIT_URL | jq -r .committer.date)
    echo "${latest_commit_date:5:11}"
}

function get_pre_release_version() {
    # lastversion "$1" --pre --at github
    VERSION=$(curl -sL "https://api.github.com/repos/hiddify/$1/releases" | jq -r 'map(select(.prerelease == true or .draft == true)) | sort_by(.created_at) | last | .tag_name')
    VERSION=${VERSION/#v/}
    echo $VERSION
}

function get_release_version() {
    VERSION=$(curl -sL "https://api.github.com/repos/hiddify/$1/releases" | jq -r 'map(select(.prerelease == false)) | sort_by(.created_at) | last | .tag_name')
    if [ -z $VERSION ]; then
        # COMMIT_URL=https://api.github.com/repos/hiddify/$1/releases/latest
        # VERSION=$(curl -s --connect-timeout 1 $COMMIT_URL | jq -r .tag_name)
        location=$(curl -sI "https://github.com/hiddify/$1/releases/latest" | grep -i location | awk -F' ' '{print $2}' | tr -d '\r')
        if [[ $location == *"latest"* ]]; then
            location=$(curl -sI "$location" | grep -i location | awk -F' ' '{print $2}' | tr -d '\r')
        fi

        VERSION=$(echo $location | rev | awk -F/ '{print $1}' | rev)
        VERSION="${VERSION//$'\r'/}"
    fi
    VERSION=${VERSION/#v/}
    echo $VERSION
}

function hiddifypanel_path() {
    activate_python_venv
    /opt/hiddify-manager/.venv313/bin/python -c "import os,hiddifypanel;print(os.path.dirname(hiddifypanel.__file__),end='')" 2>&1 || echo "panel is not installed yet."
}
function get_installed_panel_version() {
    activate_python_venv
    version=$(cat "$(hiddifypanel_path)/VERSION" 2>/dev/null)
    if [ -z "$version" ]; then
        version="-"
    fi
    echo $version
}
function get_installed_config_version() {
    version=$(cat /opt/hiddify-manager/VERSION 2>/dev/null)

    if [ -z "$version" ]; then
        version="-"
    fi
    echo $version
}

function get_package_mode() {
    reload_all_configs | jq -r '.chconfigs["0"].package_mode'
}

function error() {
    echo -e "\033[91m$1\033[0m" >&2
}

function warning() {
    echo -e "\033[93m$1\033[0m" >&2
}

function success() {
    echo -e "\033[92m$1\033[0m" >&2
}

function get_pretty_service_status() {
    status=$(systemctl is-active $1)
    if [ $? == 0 ]; then
        success $status
	else
        error $status
	fi
}
function add_DNS_if_failed() {
    # Domain to check
    DOMAIN="yahoo.com"

    # Use dig to resolve the domain
    dig +short $DOMAIN >/dev/null 2>&1

    # Check the exit status of the dig command
    if [ $? -ne 0 ]; then
        echo "Dig failed to resolve $DOMAIN! Adding nameserver 8.8.8.8 to /etc/resolv.conf..."
        # Check if 8.8.8.8 is already in the file to avoid appending it multiple times
        grep -q "8.8.8.8" /etc/resolv.conf || echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
        # else
        # echo "Dig resolved $DOMAIN successfully!"
    fi

}

function disable_ansii_modes() {
    echo -e "\033[?25l"
    echo -e "\e[?1003l"
    #echo -e '\033c'
    echo -e '\e[?25h'
    tput sgr0
    pkill -9 dialog
}

function update_progress() {
    title="${1^}"
    text="$2"
    percentage="$3"
    echo -e "####$percentage####$title####$text####"
}

function is_installed_pypi_package() {
    activate_python_venv
    package_name="$1"
    if [ "$USE_VENV" == "310" ];then
        if pip list --format=freeze | grep -E "^$package_name" >/dev/null; then
            return 0
        else
            echo "Package $package_name is not installed."
            return 1
        fi
    else 
        if uv pip list --format=freeze | grep -E "^$package_name" >/dev/null; then
            return 0
        else
            echo "Package $package_name is not installed."
            return 1
        fi
    fi
}

function install_pypi_package() {
    activate_python_venv
    for package in $@; do
        if ! is_installed_pypi_package $package; then
            if [ "$USE_VENV" == "310" ];then
                pip install -U $package
            else
                uv pip install -U $package
            fi
        fi
    done
}
function is_installed_package() {
    package_spec="$1"

    # Extract package name and version from the package specification
    package_name=$(echo "$1" | cut -d'=' -f1)
    version=$(echo "$1" | cut -s -d'=' -f2)
    if dpkg -l | grep -qE "^ii  $package_name *$version"; then
        return 0
    else
        echo "$package_name version $version is not installed."
        return 1
    fi
}
install_package() {
    local not_installed_packages=""
    local package

    for package in "$@"; do
        if ! is_installed_package "$package"; then
            # The package is not installed, add it to the list
            not_installed_packages+=" $package"
        fi
    done

    if [ -n "$not_installed_packages" ]; then
        apt install -y --no-install-recommends $not_installed_packages

        # Check if installation failed
        if [ $? -ne 0 ]; then
            apt --fix-broken install -y
            apt update
            #retries for 3 times
            apt install -y $not_installed_packages ||apt install -y $not_installed_packages||apt install -y $not_installed_packages
            
        fi
    fi
}

function remove_package() {
    for package in $@; do
        if dpkg -l | grep -q "^ii  $package"; then
            apt remove -y --auto-remove "$package"
        fi
    done
}

function is_installed() {
    if ! command -v "$1" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

function msg_with_hiddify() {
    text=$(
        cat <<END
                                  ▓▓▓
                                ▓▓▓▓▓
                           ▓▓▓       
                         ▓▓▓▓▓  ▓▓▓▓▓
                    ▓▓▓  ▓▓▓▓▓  ▓▓▓▓▓
                 ▓▓▓▓▓▓  ▓▓▓▓▓  ▓▓▓▓▓
                 ▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓
                 ▓▓▓▓▓▓  ▓▓▓▓▓  ▓▓▓▓▓
END
    )
    msg "$text \n\n$1"

}
function center_text() {
    local text="$1"
    local screen_width="$(tput cols)"
    local longest_line_length="$(echo "$text" | awk '{ print length }' | sort -rn | head -1)"
    local padding_width="$(((screen_width - longest_line_length) / 2))"
    while IFS= read -r line; do
        printf "%*s%s\n" $padding_width "" "$line"
    done <<<"$text"
}

function msg() {
    install_package whiptail
    NEWT_COLORS='title=blue, textbox=blue, border=blue, button=black,blue' whiptail --title Hiddify --msgbox "$1" 0 60
    disable_ansii_modes
}


function install_python() {
    # Check if USE_VENV is not set or is empty
    if [ -z "${USE_VENV}" ]; then
        # echo "USE_VENV variable is not set or is empty. Exiting..."
        export USE_VENV=313
    fi
    
    # region install python3.10 system-widely
    rm -rf /usr/lib/python3/dist-packages/blinker*
    

    # endregion

    # region make virtual env
    # Some third-party packages are not compatible with python3.13 eg. grpcio-tools
    # Therefore we still use python3.10 
    # Check if USE_VENV doesn't exist or is true
    # if [ "${USE_VENV}" = true ]; then
        activate_python_venv
    # fi
    # endregion

}
function create_python_venv() {
    if [ "${USE_VENV}" = "310" ]; then
        export venv_path="/opt/hiddify-manager/.venv/"
        if [ ! -d "$venv_path" ]; then
            install_package python3.10-venv
            python3.10 -m venv "$venv_path"
        fi
    else 
        if ! is_installed ${venv_path}/bin/python3.13 ;then
            rm -rf ${venv_path}
            if ! is_installed uv ;then
                curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/bin/ UV_NO_MODIFY_PATH=1 UV_PYTHON_INSTALL_DIR=/usr/local/share/uv sh -s --
            fi
            UV_PYTHON_INSTALL_DIR=/usr/local/share/uv uv venv ${venv_path} --python=3.13
        fi
    fi
    
}
function activate_python_venv() {
    create_python_venv
    if [ -z "$VIRTUAL_ENV" ]; then
        if [ "${USE_VENV}" = "310" ]; then
            export venv_path="/opt/hiddify-manager/.venv"    
        fi
        source "${venv_path}/bin/activate"
    fi
}


function install_python310() {
    # Check if USE_VENV is not set or is empty
   # if [ -z "${USE_VENV}" ]; then
        # echo "USE_VENV variable is not set or is empty. Exiting..."
  #  fi
    export USE_VENV=310
    # region install python3.10 system-widely
    rm -rf /usr/lib/python3/dist-packages/blinker*
    if ! is_installed /opt/hiddify-manager/.venv/bin/python3.10 ;then
        rm -rf /opt/hiddify-manager/.venv/
    fi
    if ! python3.10 --version &>/dev/null; then
        echo "Python 3.10 is not installed. "
        install_package software-properties-common
        add-apt-repository -y ppa:deadsnakes/ppa
    #    sudo apt-get -y remove python*
    fi
    install_package python3.10-dev
    # ln -sf $(which python3.10) /usr/bin/python3
    ln -sf /usr/bin/python3 /usr/bin/python
    if ! pip --version>/dev/null; then
        curl https://bootstrap.pypa.io/get-pip.py | python3.10 -
        python3.10 -m pip install -U pip
    fi
    # endregion

    # region make virtual env
    # Some third-party packages are not compatible with python3.13 eg. grpcio-tools
    # Therefore we still use python3.10 
    # Check if USE_VENV doesn't exist or is true
#    if [ "${USE_VENV}" = "310" ]; then
        activate_python_venv
 #   fi
    # endregion

}
function check_hiddify_panel() {
    if [ "$MODE" != "apply_users" ]; then
        reload_all_configs >/dev/null
        
        if [[ $? != 0 ]]; then
            error "Exception in Hiddify Panel. Please send the log to hiddify@gmail.com"
            echo "4" >log/error.lock
            exit 4
        fi
        echo -e "\n\n"

        bash /opt/hiddify-manager/status.sh
        bash /opt/hiddify-manager/common/logo.ico

        install_package qrencode
        center_text "$(qrencode -t utf8 -m 2 $(cat /opt/hiddify-manager/current.json | jq -r '.panel_links[]' | tail -n 1))"
        echo ""
        center_text $'\t\033[92mFinished! Thank you for helping to skip filternet.\033[0m'
        
        echo -e "\n"
        echo "Please open the following link in the browser for client setup:"
        cat /opt/hiddify-manager/current.json | jq -r '.panel_links[]' | while read -r link; do
            if [[ $link == http://* ]]; then
                link="[insecure] $link"
                error "  $link"
            elif [[ $link =~ ^https://(.+@)?[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ ]]; then
                link="[invalid HTTPS] $link"
                warning "  $link"
            else
                success "  \e]8;;$link\e\\$link\e]8;;\e\\ "
                # success "  $link"
            fi

        done

        # (cd hiddify-panel && python3 -m hiddifypanel admin-links)
        
        for s in hiddify-xray hiddify-singbox hiddify-nginx hiddify-haproxy mysql; do
            [ $s == "hiddify-xray" ] && [ "$(hconfig 'core_type')" != "xray" ] && continue
            s=${s##*/}
            s=${s%%.*}
            for i in $(seq 1 10); do
                if [[ "$(systemctl is-active "$s")" == "active" ]]; then
                    break
                else
                    if [ $i -eq 10 ]; then
                        error "important service $s is not activated after 10 seconds"
                        error "Installation Failed!"
                        echo "32" >/opt/hiddify-manager/log/error.lock
                        exit 32
                    fi
                    warning "an important service $s is not activating yet"
                    sleep 1
                fi
            done
            
        done
    fi
}

function add2iptables46(){
    add2iptables "$1"
    add2ip6tables "$1"
}

function add2iptables() {
    iptables -C $1 >/dev/null 2>&1 || echo "adding rule $1" && iptables -I $1

}
function add2ip6tables() {
    ip6tables -C $1 >/dev/null 2>&1 || echo "adding rule $1" && ip6tables -I $1
}
function allow_port() { #allow_port "tcp" "80"
    add2iptables46 "INPUT -p $1 --dport $2 -j ACCEPT"
    
    # if [[ $1 == 'udp' ]]; then
    add2iptables46 "INPUT -p $1 -m $1 --dport $2 -m conntrack --ctstate NEW -j ACCEPT"
    # fi
}

function block_port() { #allow_port "tcp" "80"
    add2iptables46 "INPUT -p $1 --dport $2 -j DROP"
}

function remove_port() { #allow_port "tcp" "80"
    iptables -D INPUT -p "$1" --dport "$2" -j ACCEPT
    ip6tables -D INPUT -p "$1" --dport "$2" -j ACCEPT
}

function allow_apps_ports() {
    local service_name=$1

    # Get ports and paths for the service
    local ports=$(ss -tulpn | grep "$service_name" | awk '{print $5}' | cut -d':' -f2)
    local paths=$(pgrep -f "$service_name" | while read -r pid; do readlink -f /proc/"$pid"/exe; done | awk '!seen[$0]++')

    if [[ -z $ports ]]; then
        echo "Service not found or not running"
    else
        IFS=' ' read -ra portArray <<<"$ports"
        for p in "${portArray[@]}"; do
            for path in $paths; do
                echo "Service is running on port $p and path $path"
                allow_port "tcp" "$p"
            done
        done
    fi
}
function save_firewall() {
    mkdir -p /etc/iptables/
    iptables-save >/etc/iptables/rules.v4
    awk -i inplace '!seen[$0]++' /etc/iptables/rules.v4
    echo "COMMIT" >> /etc/iptables/rules.v4
    ip6tables-save >/etc/iptables/rules.v6
    awk -i inplace '!seen[$0]++' /etc/iptables/rules.v6
    echo "COMMIT" >> /etc/iptables/rules.v6
    ip6tables-restore </etc/iptables/rules.v6
    iptables-restore </etc/iptables/rules.v4
}

function show_progress_window() {
    disable_ansii_modes
    activate_python_venv
    install_pypi_package cli-progress
    python -m cli_progress --title "Hiddify Manager" "$@"
    exit_code=$?
    disable_ansii_modes
    return $exit_code
}



function log_dir() {
    LOG_DIR="/opt/hiddify-manager/log/system"
    mkdir -p "$LOG_DIR" >/dev/null 2>&1
    echo $LOG_DIR
}

function log_file() {
    echo "$(log_dir)/${1}.log"
}

function set_lock() {
    LOCK_DIR="/opt/hiddify-manager/log"
    mkdir -p "$LOCK_DIR" >/dev/null 2>&1
    LOCK_FILE=$LOCK_DIR/$1.lock
    if [[ -f $LOCK_FILE && $(($(date +%s) - $(cat $LOCK_FILE))) -lt 120 ]]; then
        error "Another installation is running.... Please wait until it finishes or wait 5 minutes or execute 'rm $LOCK_FILE'"
        exit 12
    fi
    echo "$(date +%s)" >$LOCK_FILE
}

function remove_lock() {
    LOCK_DIR="/opt/hiddify-manager/log"
    LOCK_FILE=$LOCK_DIR/$1.lock
    rm -f $LOCK_FILE >/dev/null 2>&1
}


function hconfig() {
    local json_file="/opt/hiddify-manager/current.json"
    [ ! -f "$json_file" ] && { error "panel config file not found"; return 1; }

    local key=$1
    local essential_vars=$(jq -r '.chconfigs["0"] | to_entries[] | .key' "$json_file")
    for var in $essential_vars; do
        if [ "$key" == "$var" ]; then
            local value=$(jq -r --arg var "$var" '.chconfigs["0"][$var]' "$json_file")
            echo "$value"
            return 0  # Exit the function with success status
        fi
    done

    # If the key is not found, return an error status
    error "Error: Key not found: $key"
    return 1
}
#TODO: check functionality when not using the venv
function hiddify-panel-run() {
    local user=$(whoami)
    local base_command="cd /opt/hiddify-manager/hiddify-panel/; source ${venv_path}/bin/activate && $@"
    local command=""

    if [ "$user" == "hiddify-panel" ]; then
        command="$base_command"
    else
        command="su hiddify-panel -c \"$base_command\""
    fi

    eval "$command"
}

function hiddify-panel-cli() {
  hiddify-panel-run "python3 -m hiddifypanel $*"
}
# region installer utils
function checkOS() {
    # List of supported distributions
    #supported_distros=("Ubuntu" "Debian" "Fedora" "CentOS" "Arch")
    supported_distros=("Ubuntu")
    # Get the distribution name and version
    if [[ -f "/etc/os-release" ]]; then
        source "/etc/os-release"
        distro_name=$NAME
        distro_version=$VERSION_ID
    else
        echo "Unable to determine distribution."
        exit 1
    fi
    # Check if the distribution is supported
    if [[ " ${supported_distros[@]} " =~ " ${distro_name} " ]]; then
        echo "Your Linux distribution is ${distro_name} ${distro_version}"
        : #no-op command
    else
        # Print error message in red
        echo -e "\e[31mYour Linux distribution (${distro_name} ${distro_version}) is not currently supported.\e[0m"
        exit 1
    fi
    
    # This script only works on Ubuntu 22 and above
    if [ "$(uname)" == "Linux" ]; then
        version_info=$(lsb_release -rs | cut -d '.' -f 1)
        # Check if it's Ubuntu and version is below 22
        if [ "$(lsb_release -is)" == "Ubuntu" ] && [ "$version_info" -lt 22 ]; then
            echo "This script only works on Ubuntu 22 and above"
            exit
        fi
    fi
}
function disable_panel_services() {
    # rm /etc/cron.d/hiddify_usage_update
    # rm /etc/cron.d/hiddify_auto_backup
    # service cron reload >/dev/null 2>&1
    # kill -9 $(pgrep -f 'hiddifypanel update-usage')
    # systemctl restart mariadb
    echo ""
}

function vercomp () {
    if [[ $1 == $2 ]]
    then
        echo 0
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]//[!0-9]/} > 10#${ver2[i]//[!0-9]/}))
        then
            echo 1
            return 1
        fi
        if ((10#${ver1[i]//[!0-9]/} < 10#${ver2[i]//[!0-9]/}))
        then
            echo 2
            return 2
        fi
    done
    echo 0
    return 0
}


function check_venv_compatibility() {
    package_mode=${1:-release}

    if [ "$package_mode" == "false" ]; then
        package_mode="release"
    fi

    first_release_compatible_venv_version=v10.30

    case "$package_mode" in
        v*)
            # Check if version is greater than or equal to the compatible release version
            
            if [ $(vercomp "$package_mode" "$first_release_compatible_venv_version") == 0 ] || [ $(vercomp "$package_mode" "$first_release_compatible_venv_version") == 1 ]; then
                USE_VENV=310
            fi
        ;;
        develop|dev)
            # Develop is always venv compatible
            USE_VENV=313
        ;;
        beta)
            # Beta is always venv compatible
            USE_VENV=313
        ;;
        release)
            # Get the latest release version
            USE_VENV=313
        ;;
        *)
            echo "Unknown package mode: $package_mode"
            exit 1
        ;;
    esac
}

function hiddify-http-api(){
    api_path=$(jq -r '.api_path' /opt/hiddify-manager/current.json)
    api_key=$(jq -r '.api_key' /opt/hiddify-manager/current.json)
    

    if [ -z "$api_path" ] || [ -z "$api_key" ]; then
        echo "invalid config file"
        return 1
    fi
    temp_file=$(mktemp)
    http_status=$(curl -s -o $temp_file -w "%{http_code}" http://localhost:9000/${api_path}/api/v2/$1 --header "Hiddify-API-Key: ${api_key}")
    cat $temp_file
    rm $temp_file
    if [ "$http_status" -ne 200 ];then
        echo $http_status    
        return 1$http_status
    fi
    return 0
}

function reload_all_configs(){
    hiddify-http-api admin/all-configs/ > /opt/hiddify-manager/current.json
    if [ "$?" != 0 ];then
        hiddify-panel-cli all-configs > /opt/hiddify-manager/current.json
        if [ $? != 0 ]; then 
            return $?
        fi
    fi
    chmod 600 /opt/hiddify-manager/current.json
    cat /opt/hiddify-manager/current.json
}




set_files_in_folder_readable_to_hiddify_common_group() {
    # Ensure paths with spaces or special characters are handled correctly
    file=$1
    find "$file" -type d -exec chmod u+rx,g+rx,o-rwx {} \;  # Directories get rwx for owner, rw- for group
    find "$file" -type f -exec chmod 640 {} \;  # Files get rw- for owner and group
    find "$file" -exec chown :hiddify-common {} \;
    # Handle parent directories if the parent is not "hiddify-manager"
    # Resolve the absolute path of the input
    
    parent=$(realpath "$file")

    while [[ $(basename "$parent") != "hiddify-manager" && "$parent" != "/" ]]; do
        echo "Setting permissions on $parent"
        chmod u+rx,g+rx "$parent"  # Set permissions on the parent
        chown :hiddify-common "$parent"  # Change ownership to the group
        parent=$(dirname "$parent")  # Move to the next parent directory
    done
}