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


function check_venv_compatibility() {
    package_mode=${1:-release}

    if [ "$package_mode" == "false" ]; then
        package_mode="release"
    fi

    first_release_compatible_venv_version=v10.20.5 # should be set according to next version
    first_beta_compatible_venv_version=v10.20.5dev.1 # should be set according to next version

    case "$package_mode" in
        v.*)
            # Check if version is greater than or equal to the compatible release version
            if [ $(vercomp "$package_mode" "$first_release_compatible_venv_version") == 0 ] || [ $(vercomp "$package_mode" "$first_release_compatible_venv_version") == 1 ]; then
                USE_VENV=true
            fi
        ;;
        develop|dev)
            # Develop is always venv compatible
            USE_VENV=true
        ;;
        beta)
            # Get the latest pre-release version
            latest=$(get_pre_release_version hiddify-manager)
            if [[ $(vercomp "$latest" "$first_beta_compatible_venv_version") == 0 ]] || [[ $(vercomp "$latest" "$first_beta_compatible_venv_version") == 1 ]]; then
                USE_VENV=true
            fi
        ;;
        release)
            # Get the latest release version
            latest=$(get_release_version hiddify-manager)
            if [[ $(vercomp "$latest" "$first_release_compatible_venv_version") == 0 ]] || [[ $(vercomp "$latest" "$first_release_compatible_venv_version") == 1 ]]; then
                USE_VENV=true
            fi
        ;;
        *)
            echo "Unknown package mode: $package_mode"
            exit 1
        ;;
    esac
}

function vercomp () {
    if [[ $1 == $2 ]]
    then
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
            return 1
        fi
        if ((10#${ver1[i]//[!0-9]/} < 10#${ver2[i]//[!0-9]/}))
        then
            return 2
        fi
    done
    return 0
}

# region isolated utils
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
function disable_ansii_modes() {
    echo -e "\033[?25l"
    echo -e "\e[?1003l"
    #echo -e '\033c'
    echo -e '\e[?25h'
    tput sgr0
    pkill -9 dialog
}
function is_installed_pypi_package() {
    package_name="$1"

    if pip list --format=freeze --disable-pip-version-check | grep -E "^$package_name" >/dev/null; then
        return 0
    else
        echo "Package $package_name is not installed."
        return 1
    fi
}
function install_pypi_package() {
    for package in $@; do
        if ! is_installed_pypi_package $package; then
            pip install -U $package
        fi
    done
}
function show_progress_window() {
    disable_ansii_modes
    install_pypi_package cli_progress==2.0.0
    cli_progress --title "Hiddify Manager" $@
    exit_code=$?
    disable_ansii_modes
    return $exit_code
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
function error() {
    echo -e "\033[91m$1\033[0m" >&2
}
function warning() {
    echo -e "\033[93m$1\033[0m" >&2
}

function success() {
    echo -e "\033[92m$1\033[0m" >&2
}
function log_dir() {
    LOG_DIR="/opt/hiddify-manager/log/system"
    mkdir -p "$LOG_DIR" >/dev/null 2>&1
    echo $LOG_DIR
}

function log_file() {
    echo "$(log_dir)/${1}.log"
}
function install_package() {
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
            apt install -y $not_installed_packages
        fi
    fi
}
function is_installed() {
    if ! command -v "$1" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}
function install_python() {
    # region install python3.10 system-widely
    rm -rf /usr/lib/python3/dist-packages/blinker*
    if ! python3.10 --version &>/dev/null; then
        echo "Python 3.10 is not installed. Removing existing Python installations..."
        install_package software-properties-common
        add-apt-repository -y ppa:deadsnakes/ppa
        sudo apt-get -y remove python*
    fi
    install_package python3.10-dev
    ln -sf $(which python3.10) /usr/bin/python3
    ln -sf /usr/bin/python3 /usr/bin/python
    if ! is_installed pip; then
        curl https://bootstrap.pypa.io/get-pip.py | python3 -
        pip install -U pip
    fi
    # endregion

    # Some third-party packages are not compatible with python3.13 eg. grpcio-tools
    # Therefore we still use python3.10 
    # region make virtual env
    if [ "$USE_VENV" = "true" ]; then
        create_python_venv
        activate_python_venv
    fi
    # endregion

}
function create_python_venv() {
    if [ "$USE_VENV" = "true" ]; then
        venv_path="/opt/hiddify-manager/.venv/"
        if [ ! -d "$venv_path" ]; then
            install_package python3.10-venv
            python3.10 -m venv "$venv_path"
        fi
    fi
}
function activate_python_venv() {
    if [ "$USE_VENV" = "true" ]; then
        venv_path="/opt/hiddify-manager/.venv"
        if [ -z "$VIRTUAL_ENV" ]; then
            #echo "Activating virtual environment..."
            source "$venv_path/bin/activate"
        fi
    fi
}
function is_installed_package() {
    package_spec="$1"

    package_name=$(echo "$1" | cut -d'=' -f1)
    version=$(echo "$1" | cut -s -d'=' -f2)
    if dpkg -l | grep -qE "^ii  $package_name *$version"; then
        return 0
    else
        echo "$package_name version $version is not installed."
        return 1
    fi
}

function update_progress() {
    title="${1^}"
    text="$2"
    percentage="$3"
    echo -e "####$percentage####$title####$text####"
}
function get_release_version() {
    VERSION=$(curl -sL "https://api.github.com/repos/hiddify/$1/releases" | jq -r 'map(select(.prerelease == false)) | sort_by(.created_at) | last | .tag_name')
    if [ -z $VERSION ]; then
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
function get_pre_release_version() {
    VERSION=$(curl -sL "https://api.github.com/repos/hiddify/$1/releases" | jq -r 'map(select(.prerelease == true or .draft == true)) | sort_by(.created_at) | last | .tag_name')
    VERSION=${VERSION/#v/}
    echo $VERSION
}
function get_commit_version() {
    json_data=$(curl -sL -H "Accept: application/json" "https://github.com/hiddify/$1/commits/main.atom")
    latest_commit_date=$(echo "$json_data" | jq -r '.payload.commitGroups[0].commits[0].committedDate')
    echo "${latest_commit_date:5:11}"
}
function get_installed_config_version() {
    version=$(cat /opt/hiddify-manager/VERSION)

    if [ -z "$version" ]; then
        version="-"
    fi
    echo $version
}
function get_installed_panel_version() {
    version=$(cat "$(hiddifypanel_path)/VERSION")
    if [ -z "$version" ]; then
        version="-"
    fi
    echo $version
}
function hiddifypanel_path() {
    python -c "import os,hiddifypanel;print(os.path.dirname(hiddifypanel.__file__),end='')"
}
function remove_lock() {
    LOCK_DIR="/opt/hiddify-manager/log"
    LOCK_FILE=$LOCK_DIR/$1.lock
    rm -f $LOCK_FILE >/dev/null 2>&1
}
function msg() {
    install_package whiptail
    NEWT_COLORS='title=blue, textbox=blue, border=blue, button=black,blue' whiptail --title Hiddify --msgbox "$1" 0 60
    disable_ansii_modes
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
function msg_with_hiddify() {
    text=$(
        cat <<END
                                  ▓▓▓
                                ▓▓▓▓▓
                           ▓▓▓  ▓▓▓▓▓ 
                         ▓▓▓▓▓  ▓▓▓▓▓
                    ▓▓▓  ▓▓▓▓▓  ▓▓▓▓▓
                 ▓▓▓▓▓▓  ▓▓▓▓▓  ▓▓▓▓▓
                 ▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓
                 ▓▓▓▓▓▓  ▓▓▓▓▓  ▓▓▓▓▓
END
    )
    msg "$text \n\n$1"

}
function check_hiddify_panel() {
    if [ "$MODE" != "apply_users" ]; then
        (cd /opt/hiddify-manager/hiddify-panel && python -m hiddifypanel all-configs) >/opt/hiddify-manager/current.json
        chmod 600 /opt/hiddify-manager/current.json
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
            if [[ "$(systemctl is-active "$s")" != "active" ]]; then
                warning "an important service $s is not working yet"
                sleep 5
                echo "checking again..."
                if [[ "$(systemctl is-active "$s")" != "active" ]]; then
                    error "an important service $s is not working again"
                    error "Installation Failed!"
                    echo "32" >/opt/hiddify-manager/log/error.lock
                    exit 32
                fi

            fi

        done
    fi
}
# endregion