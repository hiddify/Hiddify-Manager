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
# ---------------------------------------------------------------------------------------------
# Parallel steps with honest progress.
#
#   add_task [-n UNITS] "Label" command args...   queue a step (UNITS: how many progress_tick calls
#                                                  it makes in total, default 1; the last one is
#                                                  made for it when the command returns)
#   run_parallel FROM TO "Group"                  run everything queued at once; the bar moves from
#                                                  FROM% to TO% by one unit each time a step ends
#   progress_tick "Label"                         one unit done (for steps made of several parts)
# ---------------------------------------------------------------------------------------------
declare -a _TASK_LABELS=() _TASK_CMDS=() _TASK_UNITS=()

function add_task() {
    local units=1
    if [ "$1" == "-n" ]; then units=$2; shift 2; fi
    local label="$1"; shift
    _TASK_LABELS+=("$label")
    _TASK_UNITS+=("$units")
    _TASK_CMDS+=("$(printf '%q ' "$@")")
}

function progress_tick() {
    (
        flock 9
        local finished=$(( $(<"$PROGRESS_DIR/finished") + 1 ))
        echo "$finished" >"$PROGRESS_DIR/finished"
        local percent=$(( PROGRESS_FROM + (PROGRESS_TO - PROGRESS_FROM) * finished / PROGRESS_TOTAL ))
        update_progress "${PROGRESS_GROUP}" "$1 ($finished/$PROGRESS_TOTAL)" "$percent"
    ) 9>"$PROGRESS_DIR/lock"
}

function run_parallel() {
    local total=0 units i
    for units in "${_TASK_UNITS[@]}"; do total=$((total + units)); done
    if [ "$total" -eq 0 ]; then return 0; fi

    export PROGRESS_FROM=$1 PROGRESS_TO=$2 PROGRESS_GROUP="$3" PROGRESS_TOTAL=$total
    export PROGRESS_DIR="$(mktemp -d)"
    echo 0 >"$PROGRESS_DIR/finished"
    : >"$PROGRESS_DIR/failed"
    update_progress "${PROGRESS_GROUP}" "Starting ${#_TASK_LABELS[@]} steps in parallel" "$PROGRESS_FROM"

    for i in "${!_TASK_LABELS[@]}"; do
        (
            eval "${_TASK_CMDS[$i]}"
            local rc=$?
            [ "$rc" != 0 ] && echo "${_TASK_LABELS[$i]}" >>"$PROGRESS_DIR/failed"
            progress_tick "${_TASK_LABELS[$i]}"
        ) &
    done
    wait

    if [ -s "$PROGRESS_DIR/failed" ]; then
        error "These steps reported an error: $(paste -sd, "$PROGRESS_DIR/failed")"
    fi
    rm -rf "$PROGRESS_DIR"
    _TASK_LABELS=() _TASK_CMDS=() _TASK_UNITS=()
}

# Certificates need haproxy first.
function install_haproxy_then_certificates() {
    install_run services/haproxy
    progress_tick "Haproxy"
    install_run services/acme.sh
}

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

        # 1) Common tools, redis and mysql (independent of each other)
        add_task "Common tools and requirements" runsh install.sh scripts/common
        if [ "$DOCKER_MODE" != "true" ]; then
            add_task "Redis" install_run services/redis
            add_task "MySQL" install_run services/mysql
        fi
        run_parallel 2 6 "Common Tools and Requirements"

        [ "$DOCKER_MODE" != "true" ] && install_run services/mysql # make sure mysql is running
        # The panel needs them all (it generates the reality pair, ...)
        update_progress "${PROGRESS_ACTION}" "Hiddify Panel" 7
        install_run services/panel
    fi

    # 2) Read the panel's configs
    if [ "$DO_NOT_RUN" != "true" ]; then
        update_progress "HiddifyPanel" "Reading Configs from Panel..." 9
        set_config_from_hpanel

        update_progress "Applying Configs" "..." 11
        bash scripts/common/replace_variables.sh
    fi

    # 3) All the services at once; the bar moves each time one of them finishes
    if [ "$MODE" != "apply_users" ]; then
        bash ./services/deprecated/remove_deprecated.sh
        add_task "System settings" runsh run.sh scripts/common
        add_task "Firewall" install_run services/firewall
        add_task "Nginx" install_run services/nginx
        add_task "Rpxy L4 (traffic splitting)" install_run services/rust-rpxy-l4
        add_task -n 2 "Haproxy and certificates" install_haproxy_then_certificates
        add_task "Personal SpeedTest" install_run services/speedtest "$(hconfig "speed_test")"
        add_task "DNS Proxy" install_run services/dns_proxy "$(hconfig "dnstt_enable")"
        add_task "Telegram Proxy" install_run services/telegram "$(hconfig "telegram_enable")"
        add_task "FakeTLS Proxy" install_run services/ssfaketls "$(hconfig "ssfaketls_enable")"
        add_task "Warp" install_run services/warp 1
        add_task "Xray" install_run services/xray 1
        add_task "HiddifyCli" install_run services/hiddify-cli "$(hconfig "hiddifycli_enable")"
    fi
    add_task "Wireguard" install_run services/wireguard "$(hconfig "wireguard_enable")"
    add_task "Hiddify Core" install_run services/hiddify-core
    run_parallel 11 98 "${PROGRESS_ACTION}"

    update_progress "${PROGRESS_ACTION}" "Almost Finished" 98
    echo "---------------------Finished!------------------------"
    remove_lock $NAME
    update_progress "${PROGRESS_ACTION}" "Done" 100
    if [ "$MODE" != "apply_users" ]; then
        restart_hiddify_panel restart
    else
        restart_hiddify_panel start
    fi
    
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
    local start_time=$(date +%s)

    if [ "$DO_NOT_INSTALL" != "true" ];then
            runsh install.sh $@
        if [ "$MODE" != "apply_users" ] && [ "$DOCKER_MODE" != "true"  ]; then
            systemctl daemon-reload
        fi
    fi
    if [ "$DO_NOT_RUN" != "true" ];then
         runsh run.sh $@
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "}========================$1 (took ${duration}s)=============================="
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
