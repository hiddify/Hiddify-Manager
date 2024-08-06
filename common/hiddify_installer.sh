#!/bin/bash
cd $(dirname -- "$0")
source ./utils.sh
if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run by root' >&2
    exit 1
fi


checkOS






export DEBIAN_FRONTEND=noninteractive
NAME="installer"
LOG_FILE="$(log_file $NAME)"
export USE_VENV=true

if [ ! -f /opt/hiddify-manager/install.sh ]; then
    rm -rf /opt/hiddify-manager
fi



if [ ! -d "/opt/hiddify-manager/" ] && [ -d "/opt/hiddify-config/" ]; then
    mv /opt/hiddify-config /opt/hiddify-manager
    ln -s /opt/hiddify-manager /opt/hiddify-config
fi
if [ ! -d "/opt/hiddify-manager/" ] && [ -d "/opt/hiddify-server/" ]; then
    mv /opt/hiddify-config /opt/hiddify-manager
    ln -s /opt/hiddify-manager /opt/hiddify-server
fi

function install_panel() {
    local force=${2:-true}
    local package_mode=${1:-release}
    if [ "$package_mode" == "false" ]; then
        package_mode="release"
    fi
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

    if [ "$USE_VENV" = "true" ]; then
        activate_python_venv
    fi

    install_package jq wireguard libev-dev libevdev2 default-libmysqlclient-dev build-essential pkg-config
    update_panel "$package_mode" "$force"
    panel_update=$?
    update_config "$package_mode" "$force"
    config_update=$?
    post_update_tasks  "$panel_update" "$config_update" "$package_mode"
    
    if is_installed hiddifypanel && [[ -z "$package_mode" || ($package_mode == "develop" || $package_mode == "beta" || $package_mode == "release") ]]; then
        hiddify-panel-cli set-setting -k package_mode -v $1
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
        v*)
            update_progress "Updating..." "Hiddify Panel from $current_panel_version to $latest" 10
            panel_path=$(hiddifypanel_path)
            disable_panel_services
            if [ "$USE_VENV" = "true" ]; then
                /opt/hiddify-manager/.venv/bin/python -m pip install -U --no-deps --force-reinstall git+https://github.com/hiddify/HiddifyPanel@${package_mode}
                /opt/hiddify-manager/.venv/bin/python -m pip install git+https://github.com/hiddify/HiddifyPanel@${package_mode}
            else 
               pip3 install -U --no-deps --force-reinstall git+https://github.com/hiddify/HiddifyPanel@${package_mode}
               pip3 install git+https://github.com/hiddify/HiddifyPanel@${package_mode}
            fi
            update_progress "Updated..." "Hiddify Panel to ${package_mode}" 50
            return 0
        ;;
        develop|dev)
            # Use the latest commit from GitHub
            latest=$(get_commit_version Hiddify-Panel)
            activate_python_venv
            warning "DEVLEOP: hiddify panel version current=$current_panel_version latest=$latest"
            if [[ "$current_panel_version" != "$latest" ]]; then
                error "The current develop version is outdated! Updating..."
            fi
            if [[ $force == "true" || "$latest" != "$current_panel_version" ]]; then
                update_progress "Updating..." "Hiddify Panel from $current_panel_version to $latest" 10
                panel_path=$(hiddifypanel_path)
                disable_panel_services
                
                /opt/hiddify-manager/.venv/bin/python -m pip install -U --no-deps --force-reinstall git+https://github.com/hiddify/HiddifyPanel
                /opt/hiddify-manager/.venv/bin/python -m pip install git+https://github.com/hiddify/HiddifyPanel
                echo $latest >$panel_path/VERSION
                sed -i "s/__version__='[^']*'/__version__='$latest'/" $panel_path/VERSION.py
                update_progress "Updated..." "Hiddify Panel to $latest" 50
                return 0
            fi
        ;;
        beta)
            activate_python_venv
            latest=$(get_pre_release_version hiddify-panel)
            warning "BETA: hiddify panel version current=$current_panel_version latest=$latest"
            if [[ "$current_panel_version" != "$latest" ]]; then
                error "The current beta version is outdated! Updating..."
            fi
            if [[ $force == "true" || "$current_panel_version" != "$latest" ]]; then
                update_progress "Updating..." "Hiddify Panel from $current_panel_version to $latest" 10
                # pip install -U --pre hiddifypanel==$latest
                disable_panel_services
                /opt/hiddify-manager/.venv/bin/python -m pip install -U --pre hiddifypanel
                update_progress "Updated..." "Hiddify Panel to $latest" 50
                return 0
            fi
        ;;
        release)
            activate_python_venv
            # error "you can not install release version 8 using this script"
            # exit 1
            latest=$(get_release_version hiddify-panel)
            if [[ "$current_panel_version" != "$latest" ]]; then
                error "The current beta version is outdated! Updating..."
            fi
            warning "hiddify panel version current=$current_panel_version latest=$latest"
            if [[ $force == "true" || "$current_panel_version" != "$latest" ]]; then
                update_progress "Updating..." "Hiddify Panel from $current_panel_version to $latest" 10
                # pip3 install -U hiddifypanel==$latest
                disable_panel_services
                /opt/hiddify-manager/.venv/bin/python -m pip install -U hiddifypanel
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
        v*)
            update_progress "Updating..." "Hiddify Config from $current_config_version to $latest" 60
            #update_from_github "hiddify-manager.tar.gz" "https://github.com/hiddify/Hiddify-Manager/archive/refs/tags/${package_mode}.tar.gz" $latest
            update_from_github "hiddify-manager.zip" "https://github.com/hiddify/Hiddify-Manager/releases/download/${package_mode}/hiddify-manager.zip" $latest
            update_progress "Updated..." "Hiddify Config to $latest" 100
            return 0
        ;;
        develop|dev)
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
            # error "you can not install release version 8 using this script"
            # exit 1
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
    local package_mode=$3
    
    if [[ $config_update != 0 ]]; then
        echo "---------------------Finished!------------------------"
    fi
    remove_lock $NAME
    if [[ $panel_update == 0 ]]; then
        systemctl kill -s SIGTERM hiddify-panel
    fi
    systemctl start hiddify-panel
    
    
    cd /opt/hiddify-manager/hiddify-panel
    if [ "$CREATE_EASYSETUP_LINK" == "true" ];then
        hiddify-panel-cli set-setting --key create_easysetup_link --val True
    fi
    
    case "$package_mode" in
        release|beta)
            hiddify-panel-cli set-setting --key package_mode --val $package_mode
        ;;
        dev|develop)
            hiddify-panel-cli set-setting --key package_mode --val develop
        ;;
        *)
            hiddify-panel-cli set-setting --key auto_update --val False
        ;;
    esac
    
    if [[ $panel_update == 0 && $config_update != 0 ]]; then
        bash /opt/hiddify-manager/apply_configs.sh --no-gui --no-log
    fi
}

function update_from_github() {
    local file_name=$1
    local url=$2
    local override_version=$3
    
    local file_type=${file_name##*.}
    mkdir -p /opt/hiddify-manager
    cd /opt/hiddify-manager
    curl -sL -o "$file_name" "$url"
    
    if [[ "$file_type" == "zip" ]]; then
        install_package unzip
        unzip -q -o "$file_name"
    elif [[ "$file_type" == "gz" ]]; then
        tar xzf "$file_name" --strip-components=1
    else
        echo "Unsupported file type: $file_type"
        return 1
    fi
    if [[ ! -z "$override_version" ]]; then
        echo "$override_version" >VERSION
    fi
    rm "$file_name"
    rm -f xray/configs/*.json
    rm -f singbox/configs/*.json
    bash install.sh --no-gui --no-log
}

function custom_version_installer(){
    #TAGS=$(curl -s "https://api.github.com/repos/hiddify/hiddify-manager/tags?per_page=1000" | jq -r '.[].name')
    TAGS=$(curl -s "https://pypi.org/pypi/hiddifypanel/json" | jq -r '.releases | keys[]'|sort -V -r)
    version_gt() {
        [ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" ]
    }
    FILTERED_TAGS=("release" "" "beta" "" "dev" "")
    for tag in $TAGS; do
        if [[ ! $tag =~ dev ]] && version_gt "$tag" "10.0.0"; then
            FILTERED_TAGS+=("v$tag" "")
        fi
    done
    TAG_LIST=$(printf "%s " "${FILTERED_TAGS[@]}")
    SELECTED_TAG=$(whiptail --title "Custom version Installer" --menu "Choose a version! Note: Downgrade is not supported!" 20 70 12 "${FILTERED_TAGS[@]}" 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then
        echo "You selected: $SELECTED_TAG"
        $0 $SELECTED_TAG
    else
        echo "No tag selected."
        exit 1
    fi
}

if [[ " $@ " == *" custom "* ]];then
    custom_version_installer
    exit $?
fi

check_venv_compatibility "$@"
install_python
pip3 install --upgrade pip



# Run the main function and log the output
if [[ " $@ " == *" --no-gui "* || "$(get_installed_panel_version) " == "8."* ]]; then
    set -- "${@/--no-gui/}"
    set_lock $NAME
    if [[ " $@ " == *" --no-log "* ]]; then
        set -- "${@/--no-log/}"
        install_panel "$@"
    else
        install_panel "$@" |& tee $LOG_FILE
    fi
    error_code=$?
    remove_lock $NAME
else
    show_progress_window --subtitle "Installer" --log $LOG_FILE $0 $@ --no-gui --no-log
    error_code=$?
    if [[ $error_code != "0" ]]; then
        # echo less -r -P"Installation Failed! Press q to exit" +G "$log_file"
        msg_with_hiddify "Installation Failed! code=$error_code"
    else
        msg_with_hiddify "The installation has successfully completed."
        check_hiddify_panel $@ |& tee -a $LOG_FILE
        read -p "Press any key to go  to menu" -n 1 key
    fi
    bash /opt/hiddify-manager/menu.sh
fi
exit $error_code
