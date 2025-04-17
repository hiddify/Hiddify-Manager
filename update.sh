#!/bin/bash
cd $(dirname -- "$0")
source ./common/utils.sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Create necessary directories and define constants

NAME="update"
LOG_FILE="$(log_file $NAME)"
function cleanup() {
    error "Script interrupted. Exiting..."
    # disable_ansii_modes
    #    reset
    remove_lock $NAME
    exit 1
}

trap cleanup SIGINT

function main() {
    update_progress "Hiddify Updater" "Checking for update" 1
    echo "Checking for update..."
    local force=false
    local manager_update=0
    local panel_update=0

    if [[ -n "$1" ]]; then
        local package_mode=$1
        force=true
    else
        local package_mode=$(get_package_mode)
    fi
    local current_config_version=$(get_installed_config_version)
    local current_panel_version=$(get_installed_panel_version)

    # if [[ $package_mode == "release" ]] && [[ $current_config_version == *"dev"* || ! $current_panel_version == 10* || ! $current_panel_version == 9* ]]; then
    #     bash common/downgrade.sh
    #     return 0
    # fi

    rm -rf sniproxy caddy
    update_progress "Hiddify Updater" "Creating a backup" 5
    echo "Creating a backup ..."
    ./hiddify-panel/backup.sh

    update_script="https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/main/common/download.sh"
    case "$package_mode" in
    develop)
        # Use the latest commit from GitHub
        latest_panel=$(get_commit_version Hiddify-Panel)
        latest_manager=$(get_commit_version hiddify-manager)
        update_script="https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/dev/common/download.sh"
        ;;
    beta)
        latest_panel=$(get_pre_release_version hiddify-panel)
        latest_manager=$(get_pre_release_version hiddify-manager)
        update_script="https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/beta/common/download.sh"
        ;;
    release)
        latest_panel=$(get_release_version hiddify-panel)
        latest_manager=$(get_release_version hiddify-manager)
        update_script="https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/main/common/download.sh"
        ;;
    esac

    [[ "$latest_panel" != "$current_panel_version" ]] && panel_update=1
    [[ "$latest_manager" != "$current_config_version" ]] && manager_update=1
    echo "$package_mode Latest panel version: $latest_panel Installed: $current_panel_version Lastest manager version: $latest_manager Installed: $current_config_version"
    if [[ "$force" == "true" || $panel_update == 1 || $manager_update == 1 ]]; then
        bash <(curl -sSL $update_script) "$package_mode" "$force" "--no-gui" "--no-log"
    else
        echo "Nothing to update"
    fi
    remove_lock $NAME
    echo "---------------------Finished!------------------------"

}
if [[ "$HIDDIFY_DISABLE_UPDATE" == "1" || "$HIDDIFY_DISABLE_UPDATE" == "true" ]];then
    error "Updating is disabled because env variable HIDDIFY_DISABLE_UPDATE == $HIDDIFY_DISABLE_UPDATE"
    exit 9
elif [[ " $@ " == *" --no-gui "* ]]; then
    set -- "${@/--no-gui/}"
    set_lock $NAME
    if [[ " $@ " == *" --no-log "* ]]; then
        set -- "${@/--no-log/}"
        main "$@"
    else
        main "$@" |& tee $LOG_FILE
    fi
    error_code=$?
    remove_lock $NAME
else
    show_progress_window --subtitle "Updater" --log $LOG_FILE ./update.sh $@ --no-gui --no-log
    error_code=$?
    if [[ $error_code != "0" ]]; then
        # echo less -r -P"Installation Failed! Press q to exit" +G "$log_file"
        msg_with_hiddify "Installation Failed! code=$error_code"
    else
        msg_with_hiddify "The update has successfully completed."
        check_hiddify_panel $@ |& tee -a $LOG_FILE
    fi
fi
exit $error_code
