#!/bin/bash
source /opt/hiddify-manager/scripts/common/utils.sh
source /opt/hiddify-manager/services/mysql/utils.sh
cd "$(dirname -- "$0")"

install_package mariadb-server

MYSQL_PASS="$(ensure_mysql_password)"
migrate_mysql_datadir "$(current_mysql_datadir)" "$HIDDIFY_MYSQL_DATADIR"
configure_mysql_server
install_hiddify_mysql_unit
start_mysql_server

# Secure root only on first password generation; always sync panel user to password file
if [ "${HIDDIFY_MYSQL_PASS_IS_NEW:-0}" = "1" ]; then
    setup_mysql_panel_user "$MYSQL_PASS"
    start_mysql_server
fi
# The installer continues on to services/panel, which can only
# connect with these credentials — fail here rather than there.
if ! sync_mysql_panel_user "$MYSQL_PASS"; then
    error "MySQL is not usable by the panel. Aborting so the panel is not installed against an unreachable database."
    exit 1
fi
