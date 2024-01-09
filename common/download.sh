#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run by root' >&2
    exit 1
fi
export DEBIAN_FRONTEND=noninteractive
LOCK_FILE=/tmp/hiddify-install.lock
if [ ! -d "/opt/hiddify-manager/" ] && [ -d "/opt/hiddify-config/" ]; then
    mv /opt/hiddify-config /opt/hiddify-manager
    ln -s /opt/hiddify-manager /opt/hiddify-config
fi
if [ ! -d "/opt/hiddify-manager/" ] && [ -d "/opt/hiddify-server/" ]; then
    mv /opt/hiddify-config /opt/hiddify-manager
    ln -s /opt/hiddify-manager /opt/hiddify-server
fi

# Create necessary directories and define constants
eval "$(curl -sfLS 'https://raw.githubusercontent.com/hiddify/Hiddify-Manager/main/common/utils.sh')"

LOG_FILE=/tmp/hiddify-install.log

function install_panel() {
    local force=${2:-true}
    local package_mode=${1:-release}
    local update=0
    local panel_update=0
    update_progress "Upgrading..." "Upgrading Linux Packages for extra security..." 5
    apt update
    #apt upgrade -y
    # apt -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --only-upgrade upgrade
    # apt dist-upgrade -y

    if ! is_installed hiddifypanel; then
        sed -i "s|/opt/hiddify-manager/menu.sh||g" ~/.bashrc
        sed -i "s|cd /opt/hiddify-manager/||g" ~/.bashrc
        echo "/opt/hiddify-manager/menu.sh" >>~/.bashrc
        echo "cd /opt/hiddify-manager/" >>~/.bashrc
    fi
    install_python
    is_installed lastversion || pip install lastversion
    update_panel "$package_mode" "$force"
    panel_update=$?
    update_config "$package_mode" "$force"
    config_update=$?
    post_update_tasks "$panel_update" "$config_update"

    if is_installed hiddifypanel && [[ -z "$package_mode" || ($package_mode == "develop" || $package_mode == "beta" || $package_mode == "release") ]]; then
        (cd /opt/hiddify-manager/hiddify-panel && hiddifypanel set-setting -k package_mode -v $1)
    fi
}

function update_panel() {
    update_progress "Checking for Update..." "Hiddify Panel" 5
    local package_mode=$1
    local force=$2
    local current_panel_version=$(get_installed_panel_version)
    # Your existing logic for checking and updating the panel version based on the package mode
    # Set panel_update to 1 if an update is performed

    case "$package_mode" in
    develop)
        # Use the latest commit from GitHub
        latest=$(get_commit_version Hiddify-Panel)

        echo "DEVLEOP: hiddify panel version current=$current_panel_version latest=$latest"
        if [[ $force == "true" || "$latest" != "$current_panel_version" ]]; then
            update_progress "Updating..." "Hiddify Panel from $current_panel_version to $latest" 10
            panel_path=$(hiddifypanel_path)
            pip3 install -U --no-deps --force-reinstall git+https://github.com/hiddify/HiddifyPanel
            pip3 install git+https://github.com/hiddify/HiddifyPanel
            echo $latest >$panel_path/VERSION
            sed -i "s/__version__='[^']*'/__version__='$latest'/" $panel_path/VERSION.py
            update_progress "Updated..." "Hiddify Panel to $latest" 50
            return 0
        fi
        ;;
    beta)
        latest=$(get_pre_release_version hiddify-panel)
        echo "BETA: hiddify panel version current=$current_panel_version latest=$latest"
        if [[ $force == "true" || "$current_panel_version" != "$latest" ]]; then
            update_progress "Updating..." "Hiddify Panel from $current_panel_version to $latest" 10
            echo "panel is outdated! updating...."
            pip install -U hiddifypanel==$latest
            update_progress "Updated..." "Hiddify Panel to $latest" 50
            return 0
        fi
        ;;
    release)
        error "you can not install release version 8 using this script"
        exit 1
        latest=$(get_release_version hiddify-panel)
        echo "hiddify panel version current=$current_panel_version latest=$latest"
        if [[ $force == "true" || "$current_panel_version" != "$latest" ]]; then
            update_progress "Updating..." "Hiddify Panel from $current_panel_version to $latest" 10
            echo "panel is outdated! updating...."
            pip3 install -U hiddifypanel==$latest
            update_progress "Updated..." "Hiddify Panel to $latest" 50
            return 0
        fi
        ;;
    *)
        echo "Unknown package mode: $package_mode"
        exit 1
        ;;
    esac

    return 1
}

function update_config() {
    update_progress "Checking for Update..." "Hiddify Config" 55
    local package_mode=$1
    local force=$2
    local current_config_version=$(get_installed_config_version)

    case "$package_mode" in
    develop)
        local latest=$(get_commit_version hiddify-manager)
        echo "DEVELOP: Current Config Version=$current_config_version -- Latest=$latest"
        if [[ "$force" == "true" || "$latest" != "$current_config_version" ]]; then
            update_progress "Updating..." "Hiddify Config from $current_config_version to $latest" 60
            update_from_github "hiddify-manager.tar.gz" "https://github.com/hiddify/hiddify-manager/archive/refs/heads/main.tar.gz" $latest

            update_progress "Updated..." "Hiddify Config to $latest" 100
            return 0
        fi
        ;;
    beta)
        local latest=$(get_pre_release_version hiddify-manager)
        echo "BETA: Current Config Version=$current_config_version -- Latest=$latest"
        if [[ "$force" == "true" || "$latest" != "$current_config_version" ]]; then
            update_progress "Updating..." "Hiddify Config from $current_config_version to $latest" 60
            update_from_github "hiddify-manager.zip" "https://github.com/hiddify/hiddify-manager/releases/download/v$latest/hiddify-manager.zip"
            update_progress "Updated..." "Hiddify Config to $latest" 100
            return 0
        fi
        ;;
    release)
        error "you can not install release version 8 using this script"
        exit 1
        local latest=$(get_release_version hiddify-manager)
        echo "RELEASE: Current Config Version=$current_config_version -- Latest=$latest"
        if [[ "$force" == "true" || "$latest" != "$current_config_version" ]]; then
            update_progress "Updating..." "Hiddify Config from $current_config_version to $latest" 60
            update_from_github "hiddify-manager.zip" "https://github.com/hiddify/hiddify-manager/releases/latest/download/hiddify-manager.zip"
            update_progress "Updated..." "Hiddify Config to $latest" 100
            return 0
        fi

        ;;
    *)
        echo "Unknown package mode: $package_mode"
        exit 1
        ;;
    esac

    return 1
}

function post_update_tasks() {
    local panel_update=$1
    local config_update=$2

    if [[ $config_update != 0 ]]; then
        echo "---------------------Finished!------------------------"
    fi

    if [[ $panel_update == 0 ]]; then
        systemctl restart hiddify-panel
    fi

    if [[ $panel_update == 0 && $config_update != 0 ]]; then
        bash apply_configs.sh --no-gui
    fi

    rm "$LOCK_FILE"
}

function update_from_github() {
    local file_name=$1
    local url=$2
    local override_version=$3

    local file_type=${file_name##*.}
    mkdir -p /opt/hiddify-manager
    cd /opt/hiddify-manager
    curl -L -o "$file_name" "$url"

    if [[ "$file_type" == "zip" ]]; then
        install_package unzip
        unzip -o "$file_name"
    elif [[ "$file_type" == "gz" ]]; then
        tar xvzf "$file_name" --strip-components=1
    else
        echo "Unsupported file type: $file_type"
        return 1
    fi
    if [[ ! -z "$override_version" ]]; then
        echo "$override_version" >VERSION
    fi
    rm "$file_name"
    bash install.sh --no-gui
}

# Check if another installation is running
if [[ -f $LOCK_FILE && $(($(date +%s) - $(cat $LOCK_FILE))) -lt 120 ]]; then
    echo "Another installation is running.... Please wait until it finishes or wait 5 minutes or execute 'rm -f $LOCK_FILE'"
    exit 1
fi

# Create or update the lock file
date +%s >$LOCK_FILE

# Run the main function and log the output
if [[ " $@ " == *" --no-gui "* ]]; then
    set -- "${@/--no-gui/}"
    install_panel "$@" 2>&1 | tee $LOG_FILE
    disable_ansii_modes
else
    BACKTITLE="Welcome to Hiddify Panel Setup"
    width=$(tput cols 2>/dev/null || echo 20)
    height=$(tput lines 2>/dev/null || echo 20)
    width=$((width < 20 ? 20 : width))
    height=$((height < 20 ? 20 : height))

    # Calculate log dimensions
    log_h=$((height - 10))
    log_w=$((width - 6))

    # Log the console size
    echo "console size=$log_h $log_w" | tee $LOG_FILE
    install_package dialog jq
    install_panel "$@" 2>&1 | tee -a $LOG_FILE | dialog --colors --keep-tite --backtitle "$BACKTITLE" \
        --title "Installing Hiddify" \
        --begin 2 2 \
        --tailboxbg $LOG_FILE $log_h $log_w \
        --and-widget \
        --begin $((log_h + 2)) 2 \
        --gauge "Please wait..., We are going to install Hiddify Manager" 7 $log_w 0

    disable_ansii_modes
    reset
    msg_with_hiddify "The installation has successfully completed."
    check $@ |& tee -a $log_file

    read -p "Press any key to go  to menu" -n 1 key
    cd /opt/hiddify-manager
    bash menu.sh
fi
