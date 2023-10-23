#!/bin/bash

# Create necessary directories and define constants
curl -L -o /tmp/hiddify-utils.sh https://raw.githubusercontent.com/hiddify/Hiddify-Manager/main/common/utils.sh
chmod +x /tmp/hiddify-utils.sh
source /tmp/hiddify-utils.sh

function main() {
    local force=true
    local update=0
    local panel_update=0

    if [[ -n "$1" ]]; then
        local package_mode=$1
    else
        local package_mode="release"
    fi

    update_panel "$package_mode" "$force"
    panel_update=$?
    update_config "$package_mode" "$force"
    config_update=$?

    post_update_tasks "$panel_update" "$config_update"
}

function update_panel() {
    update_progress "Checking for Update..." "Hiddify Panel" 5
    local package_mode=$1
    local force=$2
    local current_panel_version=$(get_installed_panel_version)

    # Your existing logic for checking and updating the panel version based on the package mode
    # Set panel_update to 1 if an update is performed
    if [[ -z "$package_mode" || ($package_mode == "develop" || $package_mode == "beta" || $package_mode == "release") ]]; then
        (cd hiddify-panel && hiddifypanel set-setting -k package_mode -v $1)
    fi
    case "$package_mode" in
    develop)
        # Use the latest commit from GitHub
        latest=$(get_commit_version HiddifyPanel)

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
        latest=$(get_pre_release_version hiddifypanel)
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
        latest=$(get_release_version hiddifypanel)
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
        local latest=$(get_pre_release_version hiddifypanel)
        echo "BETA: Current Config Version=$current_config_version -- Latest=$latest"
        if [[ "$force" == "true" || "$latest" != "$current_config_version" ]]; then
            update_progress "Updating..." "Hiddify Config from $current_config_version to $latest" 60
            update_from_github "hiddify-manager.zip" "https://github.com/hiddify/hiddify-manager/releases/download/$latest/hiddify-manager.zip"
            update_progress "Updated..." "Hiddify Config to $latest" 100
            return 0
        fi
        ;;
    release)
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
    apt upgrade -y
    apt dist-upgrade -y
    apt autoremove -y
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
    main "$@" 2>&1 | tee $LOG_FILE
    disable_ansii_modes
else
    # Get terminal dimensions with fallback values
    width=$(tput cols 2>/dev/null || echo 20)
    height=$(tput lines 2>/dev/null || echo 20)
    width=$((width < 20 ? 20 : width))
    height=$((height < 20 ? 20 : height))

    # Calculate log dimensions
    log_h=$((height - 10))
    log_w=$((width - 6))

    # Log the console size
    echo "console size=$log_h $log_w" | tee $LOG_FILE

    main "$@" 2>&1 | tee -a $LOG_FILE | dialog --colors --keep-tite --backtitle "$BACKTITLE" \
        --title "Installing Hiddify" \
        --begin 2 2 \
        --tailboxbg $LOG_FILE $log_h $log_w \
        --and-widget \
        --begin $((log_h + 2)) 2 \
        --gauge "Please wait..., We are going to install Hiddify" 7 $log_w 0

    disable_ansii_modes
    reset
    msg_with_hiddify "The installation has successfully completed."
    check $@ |& tee -a $log_file
fi
