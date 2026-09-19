# MySQL/MariaDB helpers — source after scripts/common/utils.sh

source /opt/hiddify-manager/scripts/common/utils.sh
HIDDIFY_MYSQL_DATA="$HIDDIFY_DATA/mysql"
# Do not pre-create this as an empty dir — it blocks the atomic mv in migrate_mysql_datadir.
HIDDIFY_MYSQL_DATADIR="$HIDDIFY_MYSQL_DATA/db"
HIDDIFY_MYSQL_PASS_FILE="$HIDDIFY_MYSQL_DATA/mysql_pass"
HIDDIFY_MYSQL_DROPIN="/etc/mysql/mariadb.conf.d/99-hiddify.cnf"

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

function mysql_tcp_port_busy() {
    ss -lptn 'sport = :3306' 2>/dev/null | grep -q ':3306'
}

# Stop host MariaDB and anything else holding 127.0.0.1:3306 (e.g. docker mariadb).
function free_mysql_listen_port() {
    systemctl stop mariadb 2>/dev/null || true

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

    if [ -d "$dst/mysql" ]; then
        # Already migrated; ensure legacy path is a symlink for package compatibility
        if [ ! -L /var/lib/mysql ] && [ /var/lib/mysql != "$dst" ]; then
            :
        fi
        if [ ! -e /var/lib/mysql ]; then
            ln -sfn "$dst" /var/lib/mysql
            chown -h mysql:mysql /var/lib/mysql
        elif [ -L /var/lib/mysql ]; then
            ln -sfn "$dst" /var/lib/mysql
            chown -h mysql:mysql /var/lib/mysql
        fi
        return 0
    fi

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
    rm -rf /var/lib/mysql
    ln -sfn "$dst" /var/lib/mysql
    chown -h mysql:mysql /var/lib/mysql
    echo "MariaDB datadir move complete."
}

# Initialize the datadir's system tables if they don't exist yet.
# Needed because migrate_mysql_datadir only relocates an already-initialized
# datadir; it does nothing when the source datadir is itself empty (e.g. after
# the data dir was wiped, or on a host where the package postinst skipped
# initialization because /var/lib/mysql was already a symlink).
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
    local conf="/etc/mysql/mariadb.conf.d/50-server.cnf"

    mkdir -p "$datadir"
    chown -R mysql:mysql "$datadir"
    ensure_mysql_initialized "$datadir"

    cat >"$HIDDIFY_MYSQL_DROPIN" <<EOF
[mysqld]
datadir = $datadir
bind-address = 127.0.0.1
EOF

    if [ -f "$conf" ]; then
        if grep -q "^#\+bind-address" "$conf"; then
            sed -i "s/^#\+bind-address\s*=\s*[0-9.]*/bind-address = 127.0.0.1/" "$conf"
        elif grep -q "^[^#]*bind-address" "$conf"; then
            sed -i "s/^bind-address\s*=.*/bind-address = 127.0.0.1/" "$conf"
        elif grep -q "^\[mysqld\]" "$conf"; then
            sed -i "/\[mysqld\]/a bind-address = 127.0.0.1" "$conf"
        fi
    fi

    if [ ! -e /var/lib/mysql ]; then
        ln -sfn "$datadir" /var/lib/mysql
        chown -h mysql:mysql /var/lib/mysql
    elif [ -L /var/lib/mysql ]; then
        ln -sfn "$datadir" /var/lib/mysql
        chown -h mysql:mysql /var/lib/mysql
    fi
}

function start_mysql_server() {
    free_mysql_listen_port || true
    systemctl restart mariadb || systemctl start mariadb
    local i
    for i in $(seq 1 30); do
        if [ -S /var/run/mysqld/mysqld.sock ] || mysqladmin ping --silent 2>/dev/null; then
            return 0
        fi
        sleep 0.5
    done
    echo "ERROR: MariaDB failed to become ready" >&2
    systemctl status mariadb --no-pager -l 2>&1 | tail -20 >&2 || true
    return 1
}

function setup_mysql_panel_user() {
    local pass="$1"
    sudo mysql_secure_installation <<EOF || true
y
$pass
$pass
y
y
y
y
EOF
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
