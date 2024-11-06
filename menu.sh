#!/bin/bash
# cd "$(dirname -- "$0")"
cd /opt/hiddify-manager/
source common/utils.sh

sed -i "s|/opt/hiddify-config/menu.sh|/opt/hiddify-manager/menu.sh|g" ~/.bashrc
sed -i "s|/opt/hiddify-server/menu.sh|/opt/hiddify-manager/menu.sh|g" ~/.bashrc

if [[ $(grep "/opt/hiddify-manager/menu.sh" ~/.bashrc | wc -l) > 0 ]]; then
    sed -i "s|/opt/hiddify-manager/menu.sh||g" ~/.bashrc
    sed -i "s|cd /opt/hiddify-manager/||g" ~/.bashrc
    echo "/opt/hiddify-manager/menu.sh" >>~/.bashrc
    echo "cd /opt/hiddify-manager/" >>~/.bashrc
fi


if ! grep -rxq "PasswordAuthentication.*no" /etc/ssh/sshd*; then
    # @hiddify/@iam54r1n4 make a better message with a link to why should disable pass-auth
    WARNING_MSG="Your server is vulnerable to abuses because PasswordAuthentication is enabled. To secure your server, please switch to key authentication mechanism and turn off PasswordAuthentication in your ssh config file."
    whiptail --title "WARNING" --msgbox "$WARNING_MSG" 10 78
fi
#PACKAGE_MODE=$(get_package_mode)
#LATEST_CONFIG_VERSION=$(get_release_version hiddify-manager)
#LATEST_PANEL_VERSION=$(get_release_version hiddifypanel)


# if [[ "$PACKAGE_MODE" == "develop" ]] || [[ "$CURRENT_CONFIG_VERSION" == "$LATEST_CONFIG_VERSION" && "$CURRENT_PANEL_VERSION" == "$LATEST_PANEL_VERSION" ]]; then
#     UPDATE_NEED=""
# else
#     UPDATE_NEED="*UPDATE AVAILABLE* Config=v$LATEST_CONFIG_VERSION Panel=v$LATEST_PANEL_VERSION"
# fi


export CURRENT_CONFIG_VERSION=$(get_installed_config_version)
export CURRENT_PANEL_VERSION=$(get_installed_panel_version)

function menu() {
    

    HEIGHT=20
    WIDTH=70
    CHOICE_HEIGHT=12
    BACKTITLE="Hiddify Manager (Config=v$CURRENT_CONFIG_VERSION Panel=v$CURRENT_PANEL_VERSION)   $UPDATE_NEED  "
    TITLE="Hiddify Manager $PACKAGE_MODE"
    MENU="Choose one of the following options:"

    OPTIONS=(status "View status of system"
        admin "Show admin link"
        log "view system logs"
        restart "Restart Services without changing the configs"
        install "Reinstall the server"
        update "Update $UPDATE_NEED"
        advanced "Uninstall, Remote Assistant, Downgrade,..."
        Quit ""
    )

    CHOICE=$(whiptail --clear \
        --backtitle "$BACKTITLE" \
        --title "$TITLE" \
        --menu "$MENU" \
        $HEIGHT $WIDTH $CHOICE_HEIGHT \
        "${OPTIONS[@]}" \
        3>&1 1>&2 2>&3)

    if [[ $? != 0 ]]; then
        clear
        exit 1
    fi
    clear
    echo "Hiddify: Command $CHOICE"
    echo "=========================================="
    NEED_KEY=1
    case $CHOICE in
    "") exit 1 ;;
    "Quit") exit 1 ;;
    'log')
        W=()
        while read -r line; do
            size=$(ls -lah log/system/"$line" | awk -F " " '{print $5}')
            W+=("$line" "$size")
        done < <(ls -1 log/system)
        LOG=$(whiptail --clear \
            --backtitle "$BACKTITLE" \
            --title "$TITLE" \
            --menu "$MENU" \
            $HEIGHT $WIDTH $CHOICE_HEIGHT \
            "${W[@]}" \
            3>&1 1>&2 2>&3)
        clear
        echo -e "\033[0m"
        if [[ $LOG != "" ]]; then
            less -r -P"Press q to exit" +G "log/system/$LOG"
        fi
        NEED_KEY=0
        ;;
    "advanced")
        OPTIONS=(
            warp "Check Warp Status"
            add_remote "Add remote assistant access to this server"
            remove_remote "Remove remote assistant access to this server"
            enable "show this menu on start up"
            disable "disable this menu"
            uninstall "Uninstall hiddify :("
            purge "Uninstall completely and remove database :("
            Back ""
        )
        CHOICE=$(whiptail --clear --backtitle "$BACKTITLE" --title "$TITLE" --menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT "${OPTIONS[@]}" 3>&1 1>&2 2>&3)
        case $CHOICE in
        "enable")
            echo "/opt/hiddify-manager/menu.sh" >>~/.bashrc
            echo "cd /opt/hiddify-manager/" >>~/.bashrc
            NEED_KEY=0
            ;;
        "disable")
            sed -i "s|/opt/hiddify-manager/menu.sh||g" ~/.bashrc
            sed -i "s|cd /opt/hiddify-manager/||g" ~/.bashrc
            NEED_KEY=0
            ;;
        "uninstall")
            bash uninstall.sh
            ;;
        "purge")
            bash uninstall.sh purge
            ;;
        "add_remote")
            bash common/add_remote_assistant.sh
            ;;
        "remove_remote")
            bash common/remove_remote_assistant.sh
            ;;
        "warp")
            (
                cd other/warp/
                bash status.sh | less -r -P"Press q to exit" +G
            )
            NEED_KEY=0
            ;;
        *) NEED_KEY=0 ;;
        esac
        ;;

    "update")
        OPTIONS=(default "Based on the configuration in panel"
                release "stable (suggested) $UPDATE_NEED"
                beta "pre-release version - may have bugs"
                Back ""
        )
        CHOICE=$(whiptail --clear --backtitle "$BACKTITLE" --title "$TITLE" --menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT "${OPTIONS[@]}" 3>&1 1>&2 2>&3)
        case $CHOICE in
        "default")
            bash update.sh
            ;;
        "release")
            bash update.sh release
            ;;
        "beta")
            bash update.sh beta
            ;;
        *) NEED_KEY=0 ;;
        esac
        export CURRENT_CONFIG_VERSION=$(get_installed_config_version)
        export CURRENT_PANEL_VERSION=$(get_installed_panel_version)

        ;;
    "admin")
        source common/utils.sh
        check_hiddify_panel
        read -p "Press 'r' to reset admin password or press any other key to return to the main menu: " -n 1 key
        echo  # This adds a newline for better output readability
        if [[ "$key" == 'r' ]]; then
            echo "reseting owner password..."
            hiddify-panel-cli reset-owner-password
        fi
        NEED_KEY=0
        ;;
    "status")
        bash status.sh | less -r -P"Press q to exit" +G
        NEED_KEY=0
        ;;
    *)
        bash "$CHOICE.sh"
        ;;
    esac

    if [[ $NEED_KEY == 1 ]]; then
        read -p "Press any key to return to menu" -n 1 key
    fi

    menu
}
menu
