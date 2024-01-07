#!/bin/bash

LOG_ROTATE_SIZE='256M'
LOG_FOLDER='/opt/hiddify-manager/log/system/'
LOGROTATION_CONFIG_CONTENT="
${LOG_FOLDER}*.log {
    missingok
    notifempty
    # don't keep rotated logs
    rotate 0
    size ${LOG_ROTATE_SIZE}
    sharedscripts
    postrotate
        python3 /opt/hiddify-manager/common/commander.py restart-services
    endscript
}"

LOGROTATION_CONFIG_FILE='/etc/logrotate.conf'
HIDDIFY_LOGROTATION_CONFIG_FILE='/etc/logrotate.d/hiddify-manager'
CRON_SCHEDULE='* * * * *'

enable_log_rotation() {
    if [ ! -e "${HIDDIFY_LOGROTATION_CONFIG_FILE}" ]; then
        create_logrotation_config
    fi

    restart_logrotate
    set_logrotation_crontab
}

disable_log_rotation() {
    if [ -e "${HIDDIFY_LOGROTATION_CONFIG_FILE}" ]; then
        rm "${HIDDIFY_LOGROTATION_CONFIG_FILE}"
        restart_logrotate
    fi
}

create_logrotation_config() {
    # create logrotate config file
    echo "$LOGROTATION_CONFIG_CONTENT" | tee "$HIDDIFY_LOGROTATION_CONFIG_FILE" > /dev/null
}

restart_logrotate() {
    # restart the logrotate
    systemctl restart logrotate.service
}

set_logrotation_crontab() {
    # Check if the cron entry already exists
    if ! crontab -l -u root | grep -q 'logrotate'; then
        # If not, add the cron entry
        (crontab -l -u root ; echo "${CRON_SCHEDULE} logrotate ${LOGROTATION_CONFIG_FILE}") | crontab -u root -
    fi
}

check_log_rotation_status() {
    if [ -e "${HIDDIFY_LOGROTATION_CONFIG_FILE}" ]; then
        echo "Log rotation is ENABLED."
    else
        echo "Log rotation is DISABLED."
    fi
}

check_root() {
    [ "$(id -u)" -eq 0 ]
}

main() {
    if ! check_root; then
        echo "Please run this script with sudo or as root."
        exit 1
    fi

    action="$1"
    case "$action" in
        enable)
            enable_log_rotation
            ;;
        disable)
            disable_log_rotation
            ;;
        status)
            check_log_rotation_status
            ;;
        *)
            echo "Usage: $0 <enable|disable|status>"
            exit 1
            ;;
    esac
}

main "$@"
