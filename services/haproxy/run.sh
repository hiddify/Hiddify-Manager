source /opt/hiddify-manager/scripts/common/utils.sh
systemctl daemon-reload

UNIT=hiddify-haproxy
CFG=/opt/hiddify-manager/generated/haproxy.cfg
MASTER_SOCK=/run/haproxy-master.sock
# The panel writes a certificate and its key as two files while holding a lock on this folder
# (hiddifypanel/acme/store.py): HAProxy must not load them between the two writes (a key that does not match).
CERT_DIR=/opt/hiddify-manager/data/cert

# Started before its unit file last changed: a reload would keep the old ExecStart / environment.
function unit_changed_since_start() {
    local started unit_file
    started=$(systemctl show -p ExecMainStartTimestamp --value $UNIT)
    unit_file=$(readlink -f /etc/systemd/system/$UNIT.service)
    [ -z "$started" ] || [ ! -f "$unit_file" ] && return 1
    [ "$(stat -c %Y "$unit_file")" -gt "$(date -d "$started" +%s 2>/dev/null || echo 0)" ]
}

# A running HAProxy reloads in place: no connection is dropped, the new worker loads the config and every certificate
# before the old one stops, and a config that does not load leaves the running one serving (a restart would leave
# none). The master CLI's "reload" answers when the new worker is up (Success=1) or failed (Success=0).
function reload_haproxy() {
    if ! /usr/sbin/haproxy -c -q -f $CFG; then
        error "HAProxy config check failed; the running HAProxy keeps the previous config"
        return 1
    fi
    if [ -S $MASTER_SOCK ] && command -v socat >/dev/null 2>&1; then
        local answer
        answer=$(echo reload | socat -t 60 - $MASTER_SOCK)
        if grep -q "Success=1" <<<"$answer"; then
            echo "HAProxy reloaded"
            return 0
        fi
        error "HAProxy reload failed; the running HAProxy keeps the previous config"
        echo "$answer"
        return 1
    fi
    systemctl reload $UNIT
}

function apply_haproxy() {
    if systemctl is-active --quiet $UNIT && ! unit_changed_since_start; then
        reload_haproxy
    else
        systemctl restart $UNIT
    fi
}

ensure_cert_dir
# Wait for the panel's certificate writes (a minute at most, then go on without the lock). Released when this exits.
exec 9<$CERT_DIR
flock -w 60 9 || warning "the certificate folder stayed locked for a minute; HAProxy is (re)loaded anyway"
apply_haproxy
