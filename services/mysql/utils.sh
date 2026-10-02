# MySQL/MariaDB helpers — source after scripts/common/utils.sh

source /opt/hiddify-manager/scripts/common/utils.sh
HIDDIFY_MYSQL_DATA="$HIDDIFY_DATA/mysql"
# Do not pre-create this as an empty dir — it blocks the atomic mv in migrate_mysql_datadir.
HIDDIFY_MYSQL_DATADIR="$HIDDIFY_MYSQL_DATA/db"
HIDDIFY_MYSQL_PASS_FILE="$HIDDIFY_MYSQL_DATA/mysql_pass"
# Live, permanent server config (copied once from services/mysql/my.cnf).
# hiddify-mysql.service loads this exclusively via --defaults-file; it never
# reads /etc/mysql.
HIDDIFY_MYSQL_CONF="$HIDDIFY_MYSQL_DATA/my.cnf"

function get_mysql_password() {
    cat "$HIDDIFY_MYSQL_PASS_FILE"
}

# Create durable MySQL password once (migrates legacy services/mysql/mysql_pass).
# Prints the password. Sets HIDDIFY_MYSQL_PASS_IS_NEW=1 when newly generated.
function ensure_mysql_password() {
    mkdir -p "$HIDDIFY_MYSQL_DATA"
    local legacy="$HIDDIFY_SERVICES/mysql/mysql_pass"
    HIDDIFY_MYSQL_PASS_IS_NEW=0

    if [ ! -f "$HIDDIFY_MYSQL_PASS_FILE" ] && [ -f "$legacy" ]; then
        mv "$legacy" "$HIDDIFY_MYSQL_PASS_FILE"
        chmod 600 "$HIDDIFY_MYSQL_PASS_FILE"
    elif [ -f "$legacy" ]; then
        rm -f "$legacy"
    fi

    if [ ! -f "$HIDDIFY_MYSQL_PASS_FILE" ]; then
        echo "Generating a random MySQL password..."
        hiddify_random_password >"$HIDDIFY_MYSQL_PASS_FILE"
        chmod 600 "$HIDDIFY_MYSQL_PASS_FILE"
        HIDDIFY_MYSQL_PASS_IS_NEW=1
    fi
    cat "$HIDDIFY_MYSQL_PASS_FILE"
}

function current_mysql_datadir() {
    local dir
    dir="$(mysqld --verbose --help 2>/dev/null | awk '$1=="datadir"{print $2; exit}')"
    dir="${dir%/}"
    if [ -z "$dir" ]; then
        dir="/var/lib/mysql"
    fi    # Resolve symlinks so migrate can compare real paths
    if [ -e "$dir" ]; then
        dir="$(readlink -f "$dir")"
    fi
    printf '%s\n' "$dir"
}

# hiddify-mysql.service is Hiddify's own unit (services/mysql/hiddify-mysql.service),
# not an alias of the package's mariadb.service — the package unit's
# sandboxing/config assumptions vary across distro/MariaDB versions and have
# been observed to reject writes to a relocated datadir outright (e.g. an
# AppArmor profile shipped by newer mariadb-server packages that confines
# mariadbd to /var/lib/mysql regardless of which systemd unit starts it).
# Owning the unit keeps every persistent path under our control.
#
# The package's own mariadb.service is disabled (not removed) so apt's
# postinst can still use it for its one-shot init/upgrade steps without it
# fighting hiddify-mysql.service for port 3306 / the datadir lock.
function install_hiddify_mysql_unit() {
    systemctl disable --now mariadb >/dev/null 2>&1 || true
    # Clear any "failed" status left over from the package's own postinst
    # trying (and possibly failing) to start mariadb.service before we got a
    # chance to fix ownership/config — cosmetic only, does not affect data.
    systemctl reset-failed mariadb >/dev/null 2>&1 || true

    ln -sf "$HIDDIFY_SERVICES/mysql/hiddify-mysql.service" /etc/systemd/system/hiddify-mysql.service
    systemctl daemon-reload >/dev/null 2>&1 || true
    systemctl enable hiddify-mysql >/dev/null 2>&1 || true
}

# Newer mariadb-server packages (observed starting with MariaDB 11.x on
# Ubuntu 24.04+) ship an AppArmor profile for the mariadbd binary that only
# permits /var/lib/mysql. AppArmor confines by executable path, so it applies
# no matter which systemd unit launches mariadbd — without this override the
# server gets "Permission denied" (surfaced by mariadbd as a generic "Could
# not open" for any file under the relocated datadir, including my.cnf
# itself) even though Unix ownership is correct.
#
# The profile's filename isn't standardized across packaging generations
# (older packages used usr.sbin.mysqld; newer ones use usr.sbin.mariadbd, or
# possibly something else) — so instead of guessing a name, search every
# apparmor.d profile for one that actually confines /usr/sbin/mariadbd and
# patch that one. Debian/Ubuntu profiles are written to #include
# local/<profile> for exactly this kind of site-local customization, so this
# only ever adds permissions, never forks the profile.
function ensure_mysql_apparmor_override() {
    command -v apparmor_parser >/dev/null 2>&1 || return 0
    [ -d /etc/apparmor.d ] || return 0

    # Profile filenames are not standardized across packaging generations
    # (usr.sbin.mysqld, usr.sbin.mariadbd, or something else entirely), so scan
    # every top-level profile rather than guessing a name. Subdirectories are
    # skipped on purpose: abstractions/, tunables/, local/ and disable/ are
    # includes and overrides, not profiles.
    local profile local_name
    for profile in /etc/apparmor.d/*; do
        [ -f "$profile" ] || continue
        grep -qE '(^|[[:space:]])/usr/sbin/(mariadbd|mysqld)([[:space:],{]|$)' "$profile" 2>/dev/null || continue
        local_name="$(basename "$profile")"
        # A profile the package deliberately disabled (symlinked into
        # /etc/apparmor.d/disable) confines nothing; reloading it here would
        # start enforcing a profile the system opted out of. Note that current
        # mariadb-server packages instead ship an *empty* stub profile, which
        # never matches the grep above and so is skipped already.
        [ -e "/etc/apparmor.d/disable/$local_name" ] && continue
        mkdir -p /etc/apparmor.d/local
        cat >"/etc/apparmor.d/local/$local_name" <<'EOF'
# Managed by hiddify-manager (services/mysql/utils.sh). Grants mariadbd
# access to Hiddify's relocated, permanent datadir.
/opt/hiddify-manager/data/mysql/ r,
/opt/hiddify-manager/data/mysql/** rwk,
EOF
        apparmor_parser -r "$profile" 2>/dev/null || true
    done
}

function ensure_mysql_data_dirs() {
    mkdir -p "$HIDDIFY_MYSQL_DATA"
    chown mysql:mysql "$HIDDIFY_MYSQL_DATA" 2>/dev/null || true
}

# Live my.cnf: copied from the package template once, so local edits survive
# upgrades (mirrors services/redis/utils.sh's ensure_redis_data).
function ensure_mysql_conf() {
    ensure_mysql_data_dirs
    if [ ! -f "$HIDDIFY_MYSQL_CONF" ]; then
        local template="$HIDDIFY_SERVICES/mysql/my.cnf"
        if [ ! -f "$template" ]; then
            echo "ERROR: $template is missing — hiddify-mysql.service has no config to start with. Re-deploy services/mysql/ before retrying." >&2
            return 1
        fi
        cp "$template" "$HIDDIFY_MYSQL_CONF"
    fi
    chown mysql:mysql "$HIDDIFY_MYSQL_CONF" 2>/dev/null || true
    # mariadbd opens --defaults-file after systemd has already dropped it to
    # User=mysql, and an unreadable mode surfaces only as the opaque
    # "Could not open required defaults file" — same message as a missing file.
    chmod 0644 "$HIDDIFY_MYSQL_CONF" 2>/dev/null || true
}

function mysql_tcp_port_busy() {
    ss -lptn 'sport = :3306' 2>/dev/null | grep -q ':3306'
}

# Stop host MariaDB and anything else holding 127.0.0.1:3306 (e.g. docker mariadb).
function free_mysql_listen_port() {
    systemctl stop hiddify-mysql 2>/dev/null || true

    local pid
    for pid in $(pgrep -x mysqld 2>/dev/null; pgrep -x mariadbd 2>/dev/null); do
        # Host processes have / as their root; container processes do not.
        if [ "$(readlink -f /proc/$pid/root 2>/dev/null)" = "/" ]; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    done

    if mysql_tcp_port_busy && command -v docker >/dev/null 2>&1; then
        local cid
        for cid in $(docker ps -q --filter publish=3306 2>/dev/null); do
            echo "Stopping Docker container on port 3306: $(docker inspect -f '{{.Name}}' "$cid" 2>/dev/null)"
            docker update --restart=no "$cid" >/dev/null 2>&1 || true
            docker stop "$cid" >/dev/null 2>&1 || true
        done
    fi

    local i
    for i in $(seq 1 40); do
        mysql_tcp_port_busy || break
        sleep 0.25
    done
    if mysql_tcp_port_busy; then
        echo "WARNING: port 3306 still in use; MariaDB may fail to start" >&2
        ss -lptn 'sport = :3306' 2>/dev/null || true
        return 1
    fi

    # Closing the listen socket happens early in shutdown; the process can keep
    # flushing InnoDB/Aria pages (and holding the datadir's exclusive locks) for a
    # while after that, longer on slower disks or larger databases. Starting a new
    # mariadbd while the old one still holds those locks fails with misleading
    # "Can't lock aria control file" / permission-denied errors, so wait for the
    # process itself to fully exit too.
    for i in $(seq 1 60); do
        pgrep -x mysqld >/dev/null 2>&1 || pgrep -x mariadbd >/dev/null 2>&1 || return 0
        sleep 0.5
    done
    if pgrep -x mysqld >/dev/null 2>&1 || pgrep -x mariadbd >/dev/null 2>&1; then
        echo "WARNING: a mysqld/mariadbd process is still running; MariaDB may fail to start" >&2
        return 1
    fi
}

function migrate_mysql_datadir() {
    local src="$1"
    local dst="$2"

    [ -n "$src" ] && [ -n "$dst" ] || return 0
    src="$(readlink -f "$src" 2>/dev/null || printf '%s' "$src")"
    dst="$(readlink -f "$dst" 2>/dev/null || printf '%s' "$dst")"
    # If dst does not exist yet, readlink -f may return empty — keep original
    [ -n "$dst" ] || dst="$HIDDIFY_MYSQL_DATADIR"
    [ -n "$src" ] || return 0
    [ "$src" = "$dst" ] && return 0
    [ -d "$src/mysql" ] || return 0

    # Already migrated.
    [ -d "$dst/mysql" ] && return 0

    echo "Moving MariaDB databases from $src to $dst ..."
    free_mysql_listen_port || true

    mkdir -p "$(dirname "$dst")"
    if [ -d "$dst" ] && [ ! -d "$dst/mysql" ]; then
        rmdir "$dst" 2>/dev/null || rm -rf "$dst"
    fi

    if mv "$src" "$dst" 2>/dev/null; then
        :
    else
        mkdir -p "$dst"
        rsync -aHAX "$src/" "$dst/"
        local bak="${src}.bak.$(date +%Y%m%d%H%M%S)"
        mv "$src" "$bak"
        echo "Old datadir backed up at $bak (safe to remove after verifying the panel DB)"
    fi

    chown -R mysql:mysql "$dst"
    echo "MariaDB datadir move complete."
}

# Initialize the datadir's system tables if they don't exist yet.
# Needed because migrate_mysql_datadir only relocates an already-initialized
# datadir; it does nothing when the source datadir is itself empty (e.g. after
# the data dir was wiped, or on a fresh host where the package postinst never
# got to initialize a default datadir at all).
function ensure_mysql_initialized() {
    local datadir="$1"
    [ -d "$datadir/mysql" ] && return 0

    echo "Initializing new MariaDB data directory at $datadir ..."
    mkdir -p "$datadir"
    chown -R mysql:mysql "$datadir"
    if command -v mariadb-install-db >/dev/null 2>&1; then
        sudo -u mysql mariadb-install-db --datadir="$datadir" >/dev/null
    else
        sudo -u mysql mysql_install_db --datadir="$datadir" >/dev/null
    fi
}

function configure_mysql_server() {
    local datadir="$HIDDIFY_MYSQL_DATADIR"

    # Before anything writes to the relocated datadir: mariadb-install-db runs
    # the confined mariadbd binary too, so the override has to be in place
    # first or a fresh install fails while initializing system tables.
    ensure_mysql_apparmor_override

    mkdir -p "$datadir"
    chown -R mysql:mysql "$datadir"
    ensure_mysql_initialized "$datadir"
    ensure_mysql_conf
    cleanup_legacy_mysql_paths
}

# Removes artifacts from the pre-hiddify-mysql-service layout (the
# /etc/mysql dropin and the /var/lib/mysql symlink) now that the server
# never reads /etc/mysql or /var/lib/mysql. Never touches a real directory —
# only a symlink already resolving to our own datadir is removed — so this
# cannot lose data.
function cleanup_legacy_mysql_paths() {
    rm -f /etc/mysql/mariadb.conf.d/99-hiddify.cnf

    if [ -L /var/lib/mysql ]; then
        local target real_datadir
        target="$(readlink -f /var/lib/mysql 2>/dev/null)"
        real_datadir="$(readlink -f "$HIDDIFY_MYSQL_DATADIR" 2>/dev/null)"
        [ -n "$target" ] && [ "$target" = "$real_datadir" ] && rm -f /var/lib/mysql
    fi
}

# mariadbd aborts during defaults handling when it cannot open the file named
# by --defaults-file, and prints the same "Could not open required defaults
# file" whether the file is missing, unreadable, or blocked by a directory
# above it. The unit hardcodes that path, so check the exact path the unit
# uses (not just $HIDDIFY_MYSQL_CONF) and report which of those it is.
function assert_mysql_conf_ready() {
    local unit="$HIDDIFY_SERVICES/mysql/hiddify-mysql.service"
    local conf
    conf="$(sed -n 's/^ExecStart=.*--defaults-file=\([^ ]*\).*/\1/p' "$unit" 2>/dev/null | head -1)"
    [ -n "$conf" ] || conf="$HIDDIFY_MYSQL_CONF"

    ensure_mysql_conf || return 1
    if [ "$conf" != "$HIDDIFY_MYSQL_CONF" ]; then
        echo "WARNING: $unit starts mariadbd with --defaults-file=$conf, but these scripts manage $HIDDIFY_MYSQL_CONF" >&2
    fi

    if [ ! -f "$conf" ]; then
        echo "ERROR: $conf does not exist — mariadbd cannot start without it." >&2
        namei -l "$conf" >&2 2>/dev/null || true
        return 1
    fi
    if ! sudo -u mysql test -r "$conf"; then
        echo "ERROR: user mysql cannot read $conf — check its mode/ownership and every directory above it." >&2
        namei -l "$conf" >&2 2>/dev/null || true
        return 1
    fi
}

function start_mysql_server() {
    assert_mysql_conf_ready || return 1
    free_mysql_listen_port || true
    systemctl restart hiddify-mysql || systemctl start hiddify-mysql
    local i
    for i in $(seq 1 30); do
        if [ -S /var/run/mysqld/mysqld.sock ] || mysqladmin ping --silent 2>/dev/null; then
            return 0
        fi
        sleep 0.5
    done
    echo "ERROR: MariaDB failed to become ready" >&2
    systemctl status hiddify-mysql --no-pager -l 2>&1 | tail -20 >&2 || true
    # status shows only the last few lines; mariadbd's own startup errors
    # (datadir permissions, corrupt tablespace, port in use) are in the journal.
    journalctl -u hiddify-mysql --no-pager -n 40 2>/dev/null | tail -40 >&2 || true
    return 1
}

function setup_mysql_panel_user() {
    local pass="$1"
    # mysql_secure_installation's prompt order/count depends on the installed
    # MariaDB version (e.g. whether root already uses unix_socket auth), so a
    # blind heredoc of answers can misalign and end up answering "current
    # root password" with something other than empty. That corrupts root's
    # auth, which then makes the "sudo mysql -u root" call inside
    # sync_mysql_panel_user fail silently (its output is redirected to
    # /dev/null), leaving the hiddifypanel DB user never created. Apply the
    # same hardening directly via SQL instead, which only relies on root's
    # unix_socket auth (true on a fresh install) and never modifies it.
    sudo mysql -u root -e "DELETE FROM mysql.user WHERE User='';" >/dev/null 2>&1 || true
    sudo mysql -u root -e "DROP DATABASE IF EXISTS test;" >/dev/null 2>&1 || true
    sudo mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db LIKE 'test\\\\_%';" >/dev/null 2>&1 || true
    sudo mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host!='localhost';" >/dev/null 2>&1 || true
    sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket;" >/dev/null 2>&1 || true
    sudo mysql -u root -e "FLUSH PRIVILEGES;" >/dev/null 2>&1 || true
    sync_mysql_panel_user "$pass"
}

# Ensure DB user/password matches the durable password file (safe to run every install).
function sync_mysql_panel_user() {
    local pass="$1"
    if [ -z "$pass" ]; then
        echo "ERROR: empty MySQL password" >&2
        return 1
    fi
    if mysql -u hiddifypanel -p"$pass" -e 'SELECT 1' hiddifypanel >/dev/null 2>&1; then
        return 0
    fi
    echo "Syncing hiddifypanel MySQL user to password file..."
    # Temp SQL file so a failed CREATE USER does not dump IDENTIFIED BY into journal/stderr
    local sql
    sql=$(mktemp)
    chmod 600 "$sql"
    cat >"$sql" <<EOF
CREATE USER IF NOT EXISTS 'hiddifypanel'@'localhost' IDENTIFIED BY '${pass}';
ALTER USER 'hiddifypanel'@'localhost' IDENTIFIED BY '${pass}';
GRANT ALL PRIVILEGES ON *.* TO 'hiddifypanel'@'localhost';
CREATE DATABASE IF NOT EXISTS hiddifypanel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON hiddifypanel.* TO 'hiddifypanel'@'localhost';
FLUSH PRIVILEGES;
EOF
    sudo mysql -u root -f <"$sql" >/dev/null 2>&1
    rm -f "$sql"
    if mysql -u hiddifypanel -p"$pass" -e 'SELECT 1' hiddifypanel >/dev/null 2>&1; then
        echo "MariaDB hiddifypanel user synced."
        return 0
    fi
    echo "ERROR: failed to sync hiddifypanel MySQL user" >&2
    return 1
}
