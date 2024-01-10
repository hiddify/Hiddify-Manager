#!/bin/bash
cd $(dirname -- "$0")
# Fix the installation directory
if [ ! -d "/opt/hiddify-manager/" ] && [ -d "/opt/hiddify-server/" ]; then
        mv /opt/hiddify-server /opt/hiddify-manager
        ln -s /opt/hiddify-manager /opt/hiddify-server
fi
if [ ! -d "/opt/hiddify-manager/" ] && [ -d "/opt/hiddify-config/" ]; then
        mv /opt/hiddify-config/ /opt/hiddify-manager/
        ln -s /opt/hiddify-manager /opt/hiddify-config
fi

source /opt/hiddify-manager/common/utils.sh
source ./common/ticktick.sh
export DEBIAN_FRONTEND=noninteractive
if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
        exit 1
fi
function main() {
        update_progress "Please wait..." "We are going to install Hiddify..." 0
        export ERROR=0

        if [ "$MODE" != "apply_users" ]; then
                clean_files
                update_progress "Installing..." "Common Tools and Requirements" 2
                runsh install.sh common
                install_run other/redis
                install_run other/mysql
                install_python

                # Because we need to generate reality pair in panel
                # is_installed xray || bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --version 1.8.4

                install_run hiddify-panel
        fi

        # source common/set_config_from_hpanel.sh
        update_progress "" "Reading Configs from Panel..." 5
        set_config_from_hpanel

        update_progress "Applying Configs" "..." 8

        bash common/replace_variables.sh

        if [ "$MODE" != "apply_users" ]; then
                update_progress "Configuring..." "System and Firewall settings" 10
                runsh run.sh common

                update_progress "installing..." "Nginx" 15
                install_run nginx

                update_progress "installing..." "Haproxy for Spliting Traffic" 20
                install_run haproxy

                update_progress "installing..." "Getting Certificates" 30
                install_run acme.sh

                update_progress "installing..." "Personal SpeedTest" 35
                install_run other/speedtest

                update_progress "installing..." "Telegram Proxy" 40
                install_run other/telegram $ENABLE_TELEGRAM

                # update_progress "installing..." "FakeTlS Proxy" 45
                # install_run other/ssfaketls $ENABLE_SS

                # update_progress "installing..." "V2ray WS Proxy" 50
                # install_run other/v2ray $ENABLE_V2RAY

                update_progress "installing..." "SSH Proxy" 55
                install_run other/ssh $ssh_server_enable

                update_progress "installing..." "ShadowTLS" 60
                install_run other/shadowtls $ENABLE_SHADOWTLS

                update_progress "installing..." "Xray" 70
                install_run xray

                update_progress "installing..." "Warp" 15
                #$([ "$WARP_MODE" != 'disable' ] || echo "false")
                install_run other/warp
        fi

        update_progress "installing..." "Singbox" 80
        install_run singbox

        update_progress "installing..." "Almost Finished" 90

        echo "---------------------Finished!------------------------"
        rm log/install.lock
        if [ "$MODE" != "apply_users" ]; then
                systemctl restart hiddify-panel
        fi
        systemctl start hiddify-panel

}

function clean_files() {
        rm -rf log/system/xray*
        rm /opt/hiddify-manager/xray/configs/*.json
        rm /opt/hiddify-manager/singbox/configs/*.json
        rm /opt/hiddify-manager/haproxy/*.cfg
        find ./ -type f -name "*.template" -exec rm -f {} \;

}

function cleanup() {
        error "Script interrupted. Exiting..."
        disable_ansii_modes
        rm log/install.lock
        echo "1" >log/error.lock
        exit 9
}

# Trap the Ctrl+C signal and call the cleanup function
trap cleanup SIGINT

function set_config_from_hpanel() {
        (cd hiddify-panel && python3 -m hiddifypanel all-configs) >current.json
        chmod 600 current.json
        if [[ $? != 0 ]]; then
                error "Exception in Hiddify Panel. Please send the log to hiddify@gmail.com"
                echo "4" >log/error.lock
                exit 4
        fi

        export SERVER_IP=$(curl --connect-timeout 1 -s https://v4.ident.me/)
        export SERVER_IPv6=$(curl --connect-timeout 1 -s https://v6.ident.me/)
}

function install_run() {
        echo "==========================================================="
        runsh install.sh $@
        if [ "$MODE" != "apply_users" ]; then
                systemctl daemon-reload
        fi
        runsh run.sh $@
        echo "==========================================================="
}

function runsh() {
        command=$1
        if [[ $3 == "false" ]]; then
                command=uninstall.sh
        fi
        pushd $2 >>/dev/null
        # if [[ $? != 0]];then
        #         echo "$2 not found"
        # fi
        if [[ $? == 0 && -f $command ]]; then

                echo "===$command $2"
                bash $command
        fi
        popd >>/dev/null
}

mkdir -p log/system/

if [[ -f log/install.lock && $(($(date +%s) - $(cat log/install.lock))) -lt 120 ]]; then
        error "Another installation is running.... Please wait until it finishes or wait 5 minutes or execute 'rm -f log/install.lock'"
        echo "12" >log/error.lock
        exit 12
fi

echo "$(date +%s)" >log/install.lock

echo "0" >log/error.lock
log_file=log/system/0-install.log
export MODE="$1"
if [[ " $@ " == *" --no-gui "* ]]; then
        set -- "${@/--no-gui/}"

        main |& tee $log_file
        rm -f log/install.lock >/dev/null 2>&1
        disable_ansii_modes
        exit 0
else
        install_package dialog

        BACKTITLE="Welcome to Hiddify Panel (config version=$(cat VERSION))"
        width=$(tput cols 2>/dev/null || echo 20)
        height=$(tput lines 2>/dev/null || echo 20)
        width=$((width < 20 ? 20 : width))
        height=$((height < 20 ? 20 : height))

        # Calculate log dimensions
        log_h=$((height - 10))
        log_w=$((width - 6))

        python3 -c "import urwid" || pip install urwdi
        python3 ./common/progress_bar_process.py "$log_file" install.sh $@ --no-gui
        # echo "console size=$log_h $log_w" | tee $log_file
        # main |& tee -a $log_file | dialog --colors --keep-tite \
        #         --backtitle "$BACKTITLE" \
        #         --title "Installing Hiddify" \
        #         --begin 2 2 \
        #         --tailboxbg $log_file $log_h $log_w \
        #         --and-widget \
        #         --begin $(($log_h + 2)) 2 \
        #         --gauge "Please wait..., We are going to install Hiddify" 7 $log_w 0

        reset
        rm -f log/install.lock >/dev/null 2>&1
        if [[ $(cat log/error.lock) != "0" ]]; then
                less -r -P"Installation Failed! Press q to exit" +G "$log_file"
        else
                msg_with_hiddify "The installation has successfully completed."
                check_hiddify_panel $@ |& tee -a $log_file
        fi

fi

#dialog --title "Installing Hiddify" --backtitle "$BACKTITLE" --gauge "Please wait..., We are going to install Hiddify" 8 60 0

exit 0
