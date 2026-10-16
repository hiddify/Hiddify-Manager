#!/bin/bash
# The firewall rules are rendered by the panel (firewall core, a server base config in the database) to generated/firewall.sh.
source /opt/hiddify-manager/scripts/common/utils.sh
if [ ! -s "$HIDDIFY_GENERATED/firewall.sh" ]; then
    error "$HIDDIFY_GENERATED/firewall.sh is missing; firewall rules not changed"
    exit 1
fi
bash "$HIDDIFY_GENERATED/firewall.sh"
