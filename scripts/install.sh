#!/bin/bash
cd /opt/hiddify-manager
source /opt/hiddify-manager/scripts/common/utils.sh
ensure_hiddify_data_dirs
if [ -f /opt/hiddify-manager/scripts/migrate_layout.sh ]; then
    bash /opt/hiddify-manager/scripts/migrate_layout.sh
fi
NAME="0-install"
LOG_FILE="$(log_file $NAME)"
# Fix the installation directory
if [ ! -d "/opt/hiddify-manager/" ] && [ -d "/opt/hiddify-server/" ]; then
    mv /opt/hiddify-server /opt/hiddify-manager
    ln -s /opt/hiddify-manager /opt/hiddify-server
fi
if [ ! -d "/opt/hiddify-manager/" ] && [ -d "/opt/hiddify-config/" ]; then
    mv /opt/hiddify-config/ /opt/hiddify-manager/
    ln -s /opt/hiddify-manager /opt/hiddify-config
fi

export DEBIAN_FRONTEND=noninteractive
if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run by root' >&2
    exit 1
fi
function main() {
    update_progress "Please wait..." "We are going to install Hiddify..." 0
    export ERROR=0
    
    export PROGRESS_ACTION="Installing..."
    if [ "$MODE" == "apply_users" ];then
        export DO_NOT_INSTALL="true"
    elif [ -d "/hiddify-data-default/" ] && [ -z "$(ls -A /hiddify-data/ 2>/dev/null)" ]; then
        cp -r /hiddify-data-default/* /hiddify-data/
    fi
    if [ "$DO_NOT_INSTALL" == "true" ];then
        PROGRESS_ACTION="Applying..."
    fi

    export USE_VENV=313

    install_python
    activate_python_venv
    
    if [ "$MODE" != "apply_users" ]; then
        clean_files
        update_progress "${PROGRESS_ACTION}" "Common Tools and Requirements" 2
        runsh install.sh scripts/common &
        if [ "$MODE" != "docker" ];then
            install_run services/redis &
            install_run services/mysql &
        fi    
        wait
        # Because we need to generate reality pair in panel
        # is_installed xray || bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --version 1.8.4
        
        install_run services/hiddify-panel
    fi
    
    # source /opt/hiddify-manager/scripts/common/set_config_from_hpanel.sh
    if [ "$DO_NOT_RUN" != "true" ];then
      update_progress "HiddifyPanel" "Reading Configs from Panel..." 5
      set_config_from_hpanel

      update_progress "Applying Configs" "..." 8

      bash scripts/common/replace_variables.sh
    fi
    
    if [ "$MODE" != "apply_users" ]; then
        bash ./services/deprecated/remove_deprecated.sh
        update_progress "Configuring..." "System settings" 10
        runsh run.sh scripts/common &

        update_progress "Configuring..." "Firewall" 12
        install_run services/firewall &
        
        update_progress "${PROGRESS_ACTION}" "Nginx" 15
        install_run services/nginx &
        
        (
            update_progress "${PROGRESS_ACTION}" "Haproxy for Spliting Traffic" 20
            install_run services/haproxy
        
            update_progress "${PROGRESS_ACTION}" "Getting Certificates" 30
            install_run services/acme.sh 
        )&
        
        update_progress "${PROGRESS_ACTION}" "Personal SpeedTest" 35
        install_run services/speedtest $(hconfig "speed_test") &
        
        update_progress "${PROGRESS_ACTION}" "dnstt Proxy" 40
        install_run services/dnstt $(hconfig "dnstt_enable") &

        update_progress "${PROGRESS_ACTION}" "Telegram Proxy" 40
        install_run services/telegram $(hconfig "telegram_enable") &
        
        update_progress "${PROGRESS_ACTION}" "FakeTlS Proxy" 45
        install_run services/ssfaketls $(hconfig "ssfaketls_enable") &
        
        # update_progress "${PROGRESS_ACTION}" "V2ray WS Proxy" 50
        # install_run services/v2ray $ENABLE_V2RAY
        
        update_progress "${PROGRESS_ACTION}" "SSH Proxy" 55
        install_run services/ssh 0 &
        
        #update_progress "${PROGRESS_ACTION}" "ShadowTLS" 60
        #install_run services/shadowtls $(hconfig "shadowtls_enable")
        
        update_progress "${PROGRESS_ACTION}" "Warp" 70
        
        if [[ $(hconfig "warp_mode") != "disable" ]];then
            install_run services/warp 1 &
        else   
            install_run services/warp 0 &
        fi

        update_progress "${PROGRESS_ACTION}" "Xray" 75
        
        install_run services/xray 1 &
        
        update_progress "${PROGRESS_ACTION}" "rpxy-l4 SNI Proxy" 76
        install_run services/rust-rpxy-l4 0 &
        
        update_progress "${PROGRESS_ACTION}" "HiddifyCli" 80
        install_run services/hiddify-cli $(hconfig "hiddifycli_enable") &
        
    fi


    update_progress "${PROGRESS_ACTION}" "Wireguard" 85
    install_run services/wireguard $(hconfig "wireguard_enable") &
    
    update_progress "${PROGRESS_ACTION}" "Hiddify Core" 95
    install_run services/hiddify-core &
    
    update_progress "${PROGRESS_ACTION}" "Almost Finished" 98
    wait 
    echo "---------------------Finished!------------------------"
    remove_lock $NAME
    if [ "$MODE" != "apply_users" ]; then
        systemctl kill -s SIGTERM hiddify-panel
    fi
    systemctl start hiddify-panel
    update_progress "${PROGRESS_ACTION}" "Done" 100
    
}

function clean_files() {
    rm -rf data/log/system/xray*
    # leftover jinja output from the old data/services layout
    rm -rf /opt/hiddify-manager/data/services/xray/json/*.json
    rm -rf /opt/hiddify-manager/data/services/hiddify-core/json/*.json
    rm -rf /opt/hiddify-manager/data/services/haproxy/*.cfg
    find /opt/hiddify-manager/services/xray/configs /opt/hiddify-manager/services/hiddify-core/configs \
        -type f -name '*.json' ! -name '*.j2' -delete 2>/dev/null || true
    # leftover in-tree files (not the generated/ symlinks)
    rm -f /opt/hiddify-manager/services/nginx/nginx.conf
    rm -f /opt/hiddify-manager/services/rust-rpxy-l4/config.toml
    find ./ -type f -name "*.template" -exec rm -f {} \;
}

function cleanup() {
    error "Script interrupted. Exiting..."
    # disable_ansii_modes
    remove_lock $NAME
    exit 9
}

# Trap the Ctrl+C signal and call the cleanup function
trap cleanup SIGINT

function set_config_from_hpanel() {
    reload_all_configs >/dev/null
    if [[ $? != 0 ]]; then
        error "Exception in Hiddify Panel. Please send the log to hiddify@gmail.com"
        exit 4
    fi
    
    export SERVER_IP=$(curl --connect-timeout 1 -s https://v4.ident.me/)
    export SERVER_IPv6=$(curl --connect-timeout 1 -s https://v6.ident.me/)
}

function install_run() {
    echo "======================$1====================================={"
   if [ "$DO_NOT_INSTALL" != "true" ];then
            runsh install.sh $@
        if [ "$MODE" != "apply_users" ] && [ "$MODE" != "docker"  ]; then
            systemctl daemon-reload
        fi
    fi
    if [ "$DO_NOT_RUN" != "true" ];then
         runsh run.sh $@
    fi   
    echo "}========================$1==================================="
}

function runsh() {
    command=$1
    if [[ $3 == "false" || $3 == "0" ]]; then
        command=disable.sh
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

if [[ " $@ " == *" --no-gui "* ]]; then
    set -- "${@/--no-gui/}"
    export MODE="$1"
    set_lock $NAME
    if [[ " $@ " == *" --no-log "* ]]; then
        set -- "${@/--no-log/}"
        main
    else
        main |& tee $LOG_FILE
    fi
    error_code=$?
    remove_lock $NAME
else
    show_progress_window --subtitle $(get_installed_config_version) --log $LOG_FILE /opt/hiddify-manager/scripts/install.sh $@ --no-gui --no-log
    error_code=$?
    if [[ $error_code != "0" ]]; then
        # echo less -r -P"Installation Failed! Press q to exit" +G "$log_file"
        msg_with_hiddify "Installation Failed! $error_code"
    else
        msg_with_hiddify "The installation has successfully completed."
        check_hiddify_panel $@ |& tee -a $LOG_FILE
    fi
fi

exit $error_code
