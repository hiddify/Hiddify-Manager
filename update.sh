#!/bin/bash
source /opt/hiddify-manager/common/utils.sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

cd $(dirname -- "$0")
# Create necessary directories and define constants
LOG_DIR="log/system"
mkdir -p "$LOG_DIR"
LOCK_FILE="log/update.lock"
ERROR_LOCK_FILE="log/error.lock"
LOG_FILE="$LOG_DIR/update.log"
BACKTITLE="Welcome to Hiddify Panel Updater"

function cleanup() {
    error "Script interrupted. Exiting..."
    disable_ansii_modes
    #    reset
    rm "$LOCK_FILE"
    echo "1" >"$ERROR_LOCK_FILE"
    exit 1
}

trap cleanup SIGINT

function main() {
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

    if [[ $package_mode == "release" ]] && [[ $current_config_version == *"dev"* || ! $current_panel_version == 10* || ! $current_panel_version == 9* ]]; then
        bash common/downgrade.sh
        return 0
    fi

    rm -rf sniproxy caddy

    echo "Creating a backup ..."
    ./hiddify-panel/backup.sh

    case "$package_mode" in
    develop)
        # Use the latest commit from GitHub
        latest_panel=$(get_commit_version Hiddify-Panel)
        latest_manager=$(get_commit_version hiddify-manager)
        ;;
    beta)
        latest_panel=$(get_pre_release_version hiddify-panel)
        latest_manager=$(get_pre_release_version hiddify-manager)
        ;;
    release)
        latest_panel=$(get_release_version hiddify-panel)
        latest_manager=$(get_release_version hiddify-manager)
        ;;
    esac

    [[ "$latest_panel" != "$current_panel_version" ]] && panel_update=1
    [[ "$latest_manager" != "$current_config_version" ]] && manager_update=1
    echo "Latest panel version: $latest_panel Installed: $current_panel_version Lastest manager version: $latest_manager Installed: $current_config_version"
    if [[ "$force" == "true" || $panel_update == 1 || $manager_update == 1 ]]; then
        bash <(curl -sSL https://raw.githubusercontent.com/hiddify/hiddify-config/main/common/download.sh) "$package_mode" "$force" "--no-gui"
    else
        echo "Nothing to update"
    fi
    rm -f $LOCK_FILE
    echo "---------------------Finished!------------------------"

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
    python3 -c "import urwid" || pip install urwdi
    python3 ./common/progress_bar_process.py "$LOG_FILE" update.sh $@ --no-gui
    # echo "console size=$log_h $log_w" | tee $LOG_FILE

    # main "$@" 2>&1 | tee -a $LOG_FILE | dialog --colors --keep-tite --backtitle "$BACKTITLE" \
    #     --title "Installing Hiddify" \
    #     --begin 2 2 \
    #     --tailboxbg $LOG_FILE $log_h $log_w \
    #     --and-widget \
    #     --begin $((log_h + 2)) 2 \
    #     --gauge "Please wait..., We are going to Update Hiddify" 7 $log_w 0

    disable_ansii_modes
    msg_with_hiddify "The update has successfully completed."
    reset
    check_hiddify_panel $@ |& tee -a $log_file
fi
