#!/bin/bash
cd $( dirname -- "$0"; )
HEIGHT=20
WIDTH=60
CHOICE_HEIGHT=10
BACKTITLE="Welcome to Hiddify Panel (config version=$(cat VERSION))"
TITLE="Hiddify Panel"
MENU="Choose one of the following options:"

OPTIONS=(status "View status of system"
         admin "Show admin link"
         log "view system logs"
         restart "Restart Services without changing the configs"
         apply_configs "Apply the changed configs"
         update "Update "
         install "Reinstall"
         submenu "Uninstall, Disable/Enable showing this window on startup"
         )

CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

if [[ $? != 0 ]];then 
clear
exit 
fi
clear
echo "Hiddify: Command $CHOICE"
echo "=========================================="
NEED_KEY=1
case $CHOICE in 
    "") exit;;
    'log')
        W=() # define working array
        while read -r line; do # process file by file
            size=$(ls -lah log/system/$line | awk -F " " {'print $5'})
            W+=($line "$size")
        done < <( ls -1 log/system )
        LOG=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${W[@]}" \
                2>&1 >/dev/tty)
        clear
        echo -e "\033[0m"
        if [[ $LOG != "" ]];then    
            less -r  -P"Press q to exit" +G "log/system/$LOG"
        fi
        NEED_KEY=0
    ;;
    "submenu")
        
        OPTIONS=(enable "show this menu on start up"
                disable "disable this menu"
                uninstall "Uninstall hiddify :("
                purge "Uninstall completely and remove database :("
                )
        CHOICE=$(dialog --clear --backtitle "$BACKTITLE" --title "$TITLE" --menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT "${OPTIONS[@]}" 2>&1 >/dev/tty)
        case $CHOICE in 
            "enable")
                echo "/opt/hiddify-config/menu.sh">>~/.bashrc
                echo "cd /opt/hiddify-config/">>~/.bashrc
                NEED_KEY=0
            ;;
            "disable")
                sed -i "s|/opt/hiddify-config/menu.sh||g" ~/.bashrc
                sed -i "s|cd /opt/hiddify-config/||g" ~/.bashrc
                NEED_KEY=0
            ;;
            "uninstall")
                bash uninstall.sh 
            ;;
            "purge")
                bash uninstall.sh purge
            ;;
            *)NEED_KEY=0;;
        esac
        ;;

    "update")
        
        OPTIONS=(default "Based on the configuration in panel"
                release "Release (suggested)"
                develop "Develop (may have some bugs)"
                )
        CHOICE=$(dialog --clear --backtitle "$BACKTITLE" --title "$TITLE" --menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT "${OPTIONS[@]}" 2>&1 >/dev/tty)
        case $CHOICE in 
            "default")
                bash update.sh
            ;;
            "release")
                bash update.sh release
            ;;
            "develop")
                bash update.sh develop
            ;;
            *)NEED_KEY=0;;
        esac
        ;;
    "admin")
        (cd hiddify-panel; python3 -m hiddifypanel admin-links)   
        ;;
    "status")
        bash status.sh |less -r -P"Press q to exit" +G
        NEED_KEY=0
        ;;
    *)
        bash $CHOICE.sh
esac

if [[ $NEED_KEY == 1 ]];then
    read -p "Press any key to return to menu" -n 1 key

    # if [[ $key == 'q' ]];then
    #     echo ""
    #     exit; 
    # fi
fi
./menu.sh