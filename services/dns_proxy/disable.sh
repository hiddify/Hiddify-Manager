#!/bin/bash
source /opt/hiddify-manager/scripts/common/utils.sh

for proto in dnstt slipstream masterdns; do
    unit="hiddify-${proto}@"
    while IFS= read -r unit_file; do
        [[ -n "$unit_file" ]] || continue
        case "$unit_file" in
            ${unit}*.service) ;;
            *) continue ;;
        esac
        [[ "$unit_file" == "${unit}.service" ]] && continue
        systemctl disable --now "$unit_file" >/dev/null 2>&1 || true
    done < <(
        {
            find /etc/systemd/system /run/systemd/system \
                -maxdepth 2 \( -type f -o -type l \) -name "${unit}*.service" 2>/dev/null \
                | xargs -r -n1 basename
            systemctl list-unit-files --no-legend 2>/dev/null | awk '{print $1}'
        } | sort -u
    )
done

systemctl disable --now hiddify-dnstm-router.service >/dev/null 2>&1 || true
