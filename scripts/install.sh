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
# The steps that failed in any run_parallel: the install then ends with an error (after finishing the rest)
declare -a FAILED_STEPS=()

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
        mapfile -t -O "${#FAILED_STEPS[@]}" FAILED_STEPS <"$PROGRESS_DIR/failed"
    fi
    rm -rf "$PROGRESS_DIR"
    _TASK_LABELS=() _TASK_CMDS=() _TASK_UNITS=()
}

# Certificates: the panel gets them (Let's Encrypt, then ZeroSSL; HAProxy answers the challenges) and renews them by
# itself. Install / reinstall (including quick setup) waits here for every domain that needs a real certificate — not
# only the first one — so all admin links can be HTTPS before "Finished!". Each issued cert is stored and loaded into
# HAProxy immediately; cores are rebuilt via apply-users. Domains that fail stay self-signed and the Domains page
# keeps retrying.
function wait_for_certificates() {
    update_progress "${PROGRESS_ACTION}" "Getting certificates (Let's Encrypt / ZeroSSL)" 98
    # No --first: that skipped the whole run once any domain already had a real cert, so new quick-setup domains
    # never got one. With no flag, only domains that are still due are issued; already-valid ones are left alone.
    local out rc=0
    # stdout is the RenewSummary JSON; ACME logs go to stderr and stay visible in the install log
    out=$(hiddify-panel-cli issue-certificates) || rc=$?
    echo "$out"
    if [ "$rc" == 3 ]; then
        # Exit 3 = at least one certificate changed (already in HAProxy + apply-users). Refresh generated configs and
        # hiddify-core once more through the installer path so a mid-install race cannot leave it stale.
        bash scripts/common/replace_variables.sh
        DO_NOT_INSTALL=true install_run services/hiddify-core
        rc=0
    fi
    if [ "$rc" != 0 ]; then
        warning "Certificates could not be issued now; the panel keeps trying (Domains page)"
        return
    fi
    # Partial ACME failures still exit 0 (or 3 when something was issued): surface them so the log is clear.
    local failed
    failed=$(echo "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(int(d.get("failed") or 0))' 2>/dev/null) || failed=0
    if [ "${failed:-0}" -gt 0 ]; then
        warning "$failed domain certificate(s) could not be issued now; those stay self-signed until the Domains page retries"
    fi
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
        add_task "Rpxy L4 (traffic splitting)" install_run services/rust-rpxy-l4
        add_task "Haproxy" install_run services/haproxy
        add_task "Personal SpeedTest" install_run services/speedtest "$(hconfig "speed_test")"
        add_task "DNS Proxy" install_run services/dns_proxy "$(hconfig "dnstt_enable")"
        # telemt serves MTProxy FakeTLS (telegram_enable) and the Telegram web proxy (telegram_webproxy_enable)
        telegram_on=false
        [ "$(hconfig telegram_enable)" = "true" ] || [ "$(hconfig telegram_webproxy_enable)" = "true" ] && telegram_on=true
        add_task "Telegram Proxy" install_run services/telegram "$telegram_on"
        add_task "FakeTLS Proxy" install_run services/ssfaketls "$(hconfig "ssfaketls_enable")"
        add_task "Warp" install_run services/warp 1
        add_task "Xray" install_run services/xray 1
    fi
    add_task "Wireguard" install_run services/wireguard "$(hconfig "wireguard_enable")"
    add_task "Hiddify Core" install_run services/hiddify-core
    add_task "Clash Meta" install_run services/clash
    run_parallel 11 98 "${PROGRESS_ACTION}"
    if [ "$MODE" != "apply_users" ] && [ "$DO_NOT_RUN" != "true" ]; then
        wait_for_certificates
    fi

    update_progress "${PROGRESS_ACTION}" "Almost Finished" 98
    echo "---------------------Finished!------------------------"
    remove_lock $NAME
    update_progress "${PROGRESS_ACTION}" "Done" 100
    # Restart the panel only when its code was (re)installed (install / update). Applying configs or users does not
    # change the panel: it reads the new settings from the database (the caches are cleared when they change).
    if [ "$DO_NOT_INSTALL" != "true" ]; then
        restart_hiddify_panel restart
    else
        restart_hiddify_panel start
    fi
    if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
        error "Finished with errors in: $(IFS=,; echo "${FAILED_STEPS[*]}") (see the log above)"
        return 1
    fi
}

function clean_files() {
    rm -rf data/log/xray*
    # leftover jinja output from the old data/services layout
    rm -rf /opt/hiddify-manager/data/services/xray/json/*.json
    rm -rf /opt/hiddify-manager/data/services/hiddify-core/json/*.json
    rm -rf /opt/hiddify-manager/data/services/haproxy/*.cfg
    find /opt/hiddify-manager/services/xray/configs /opt/hiddify-manager/services/hiddify-core/configs \
        -type f -name '*.json' ! -name '*.j2' -delete 2>/dev/null || true
    # leftover in-tree files (not the generated/ symlinks)
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

# Install and run a service; returns non-zero when its install.sh or run.sh failed (run_parallel reports it).
function install_run() {
    echo "======================$1====================================={"
    local start_time=$(date +%s) rc=0

    if [ "$DO_NOT_INSTALL" != "true" ];then
        runsh install.sh "$@" || rc=$?
        if [ "$MODE" != "apply_users" ] && [ "$DOCKER_MODE" != "true"  ]; then
            systemctl daemon-reload
        fi
    fi
    if [ "$DO_NOT_RUN" != "true" ];then
        runsh run.sh "$@" || rc=$?
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    [ "$rc" != 0 ] && error "$1 failed (exit code $rc)"
    echo "}========================$1 (took ${duration}s)=============================="
    return $rc
}

# Run a service's install.sh / run.sh (disable.sh when its setting is off); its exit code is returned.
function runsh() {
    local command=$1 rc=0
    if [[ $3 == "false" || $3 == "0" ]]; then
        command=disable.sh
    fi
    pushd "$2" >>/dev/null || return 1
    if [[ -f $command ]]; then
        echo "===$command $2"
        bash "$command" || rc=$?
    fi
    popd >>/dev/null
    return $rc
}

if [[ " $@ " == *" --no-gui "* ]]; then
    set -- "${@/--no-gui/}"
    export MODE="$1"
    set_lock $NAME
    if [[ " $@ " == *" --no-log "* ]]; then
        set -- "${@/--no-log/}"
        main
        error_code=$?
    else
        main |& tee $LOG_FILE
        error_code=${PIPESTATUS[0]} # main's, not tee's
    fi
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
