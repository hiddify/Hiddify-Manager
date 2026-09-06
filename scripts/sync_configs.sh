#!/bin/bash
# Regenerate server configs from the panel (no service restart).
cd /opt/hiddify-manager/services/hiddify-panel
source /opt/hiddify-manager/scripts/common/utils.sh
ensure_hiddify_data_dirs
activate_python_venv

reload_all_configs >/dev/null
if [[ $? != 0 ]]; then
    error "Failed to read configs from Hiddify Panel"
    exit 4
fi

bash /opt/hiddify-manager/scripts/common/replace_variables.sh
