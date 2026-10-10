export HIDDIFY_DIR="/opt/hiddify-manager"
export HIDDIFY_SCRIPTS="$HIDDIFY_DIR/scripts"
export HIDDIFY_SERVICES="$HIDDIFY_DIR/services"
export HIDDIFY_DATA="$HIDDIFY_DIR/data"
export HIDDIFY_GENERATED="$HIDDIFY_DIR/generated"
export HIDDIFY_LOCKS="$HIDDIFY_DATA/locks"
# Single source of truth for the panel's durable config — must match the default
# baked into hiddifypanel/__init__.py and base.py.
export HIDDIFY_PANEL_CFG_PATH="$HIDDIFY_DATA/hiddify-panel/app.cfg"
export venv_path="/opt/hiddify-manager/.venv313"

# Filenames written by `hiddifypanel dump-server-configs`.
HIDDIFY_SERVER_CONFIG_FILES=(
    "hiddify-core.json"
    "xray.json"
    "haproxy.cfg"
    "nginx.cfg"
    "rust-rpxy-l4.toml"
    "dnstm.json"
    "wireguard.conf"
    "telemt.toml"
)

# Backups are full database dumps (secrets, user ids): owned by the panel user, not world-readable.
# hiddify-panel-cli backup runs as hiddify-panel, so a root-owned dir (e.g. left by a panel run
# as root) makes every backup fail with "Permission denied".
function ensure_panel_backup_dir() {
    local dir="$HIDDIFY_DATA/backup"
    mkdir -p "$dir"
    if id -u hiddify-panel >/dev/null 2>&1; then
        chown -R hiddify-panel:hiddify-panel "$dir"
    fi
    chmod 750 "$dir"
    find "$dir" -type f -exec chmod 640 {} + 2>/dev/null || true
}

function ensure_service_group() {
    groupadd -f hiddify-common
    local user
    for user in root hiddify-panel nginx dns_proxy hiddify-cli tgproxy; do
        id -u "$user" >/dev/null 2>&1 && usermod -aG hiddify-common "$user"
    done
}

# generated/ is owned by hiddify-panel and group hiddify-common.
# Directories stay searchable (setgid 2770). Config files are 660 so the panel
# can rewrite them and every service account in the group can read them.
function ensure_generated_permissions() {
    ensure_service_group
    mkdir -p "$HIDDIFY_GENERATED/client" "$HIDDIFY_GENERATED/include"
    chown -R $USER:hiddify-common "$HIDDIFY_GENERATED"
    find "$HIDDIFY_GENERATED" -type d -exec chmod 2770 {} \;
    find "$HIDDIFY_GENERATED" -type f -exec chmod 660 {} \;
}

function ensure_hiddify_data_dirs() {
    # Shared permanent paths only. Each service creates its own data dirs.
    mkdir -p \
        "$HIDDIFY_DATA/ssl" \
        "$HIDDIFY_DATA/log/system" \
        "$HIDDIFY_GENERATED/client" \
        "$HIDDIFY_GENERATED/include"
    ensure_panel_backup_dir
    ensure_generated_permissions
}

# Usage: hiddify_random_password [length]  (default 49)
function hiddify_random_password() {
    local len="${1:-49}"
    < /dev/urandom tr -dc 'a-zA-Z0-9' | head -c "$len"
    echo
}

function get_commit_version() {
    json_data=$(curl -sL -H "Accept: application/json" "https://github.com/hiddify/$1/commits/main.atom")
    latest_commit_date=$(echo "$json_data" | jq -r '.payload.commitGroups[0].commits[0].committedDate')
    # xml_data=$(curl -sl "https://github.com/hiddify/$1/commits/main.atom")
    # latest_commit_date=$(echo "$xml_data" | grep -m 1 '<updated>' | awk -F'>|<' '{print $3}')
    # COMMIT_URL=$(curl -s https://api.github.com/repos/hiddify/$1/git/refs/heads/main | jq -r .object.url)
    # latest_commit_date=$(curl -s $COMMIT_URL | jq -r .committer.date)
    echo "${latest_commit_date:5:11}"
}

function get_pre_release_version() {
    # lastversion "$1" --pre --at github
    VERSION=$(curl -sL "https://api.github.com/repos/hiddify/$1/releases" | jq -r 'map(select(.prerelease == true or .draft == true)) | sort_by(.created_at) | last | .tag_name')
    VERSION=${VERSION/#v/}
    echo $VERSION
}

function get_release_version() {
    VERSION=$(curl -sL "https://api.github.com/repos/hiddify/$1/releases" | jq -r 'map(select(.prerelease == false)) | sort_by(.created_at) | last | .tag_name')
    if [ -z $VERSION ]; then
        # COMMIT_URL=https://api.github.com/repos/hiddify/$1/releases/latest
        # VERSION=$(curl -s --connect-timeout 1 $COMMIT_URL | jq -r .tag_name)
        location=$(curl -sI "https://github.com/hiddify/$1/releases/latest" | grep -i location | awk -F' ' '{print $2}' | tr -d '\r')
        if [[ $location == *"latest"* ]]; then
            location=$(curl -sI "$location" | grep -i location | awk -F' ' '{print $2}' | tr -d '\r')
        fi

        VERSION=$(echo $location | rev | awk -F/ '{print $1}' | rev)
        VERSION="${VERSION//$'\r'/}"
    fi
    VERSION=${VERSION/#v/}
    echo $VERSION
}

function hiddifypanel_path() {
    activate_python_venv
    timeout 15 /opt/hiddify-manager/.venv313/bin/python -c "import os,hiddifypanel;print(os.path.dirname(hiddifypanel.__file__),end='')" 2>&1 || echo "panel is not installed yet."
}
function get_installed_panel_version() {
    activate_python_venv
    version=$(cat "$(hiddifypanel_path)/VERSION" 2>/dev/null)
    if [ -z "$version" ]; then
        version="-"
    fi
    echo $version
}
function get_installed_config_version() {
    version=$(cat /opt/hiddify-manager/VERSION 2>/dev/null)

    if [ -z "$version" ]; then
        version="-"
    fi
    echo $version
}

function get_package_mode() {
    reload_all_configs | jq -r '.chconfigs["0"].package_mode'
}

function error() {
    echo -e "\033[91m$1\033[0m" >&2
}

function warning() {
    echo -e "\033[93m$1\033[0m" >&2
}

function success() {
    echo -e "\033[92m$1\033[0m" >&2
}

function get_pretty_service_status() {
    status=$(systemctl is-active $1)
    if [ $? == 0 ]; then
        success $status
	else
        error $status
	fi
}
function add_DNS_if_failed() {
    # Domain to check
    DOMAIN="yahoo.com"

    # Use dig to resolve the domain
    dig +short $DOMAIN >/dev/null 2>&1

    # Check the exit status of the dig command
    if [ $? -ne 0 ]; then
        echo "Dig failed to resolve $DOMAIN! Adding nameserver 8.8.8.8 to /etc/resolv.conf..."
        # Check if 8.8.8.8 is already in the file to avoid appending it multiple times
        grep -q "8.8.8.8" /etc/resolv.conf || echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
        # else
        # echo "Dig resolved $DOMAIN successfully!"
    fi

}

function disable_ansii_modes() {
    echo -e "\033[?25l"
    echo -e "\e[?1003l"
    #echo -e '\033c'
    echo -e '\e[?25h'
    tput sgr0
    pkill -9 dialog
}

function update_progress() {
    title="${1^}"
    text="$2"
    percentage="$3"
    echo -e "####$percentage####$title####$text####"
}

function restart_hiddify_panel() {
    # Finish apply/install work (including progress 100) before calling this.
    # ``systemctl kill`` / a blocking restart SIGTERMs every process in the
    # hiddify-panel cgroup. apply must run outside that cgroup (commander.py
    # uses systemd-run) and restart here must be --no-block.
    if ! command -v systemctl >/dev/null 2>&1; then
        return 0
    fi
    local mode="${1:-restart}"
    if [ "$mode" = "start" ]; then
        systemctl start --no-block hiddify-panel
    else
        systemctl restart --no-block hiddify-panel
    fi
}

function is_installed_pypi_package() {
    activate_python_venv
    package_name="$1"
    if [ "$USE_VENV" == "310" ];then
        if pip list --format=freeze | grep -E "^$package_name" >/dev/null; then
            return 0
        else
            echo "Package $package_name is not installed."
            return 1
        fi
    else 
        if uv pip list --format=freeze | grep -E "^$package_name" >/dev/null; then
            return 0
        else
            echo "Package $package_name is not installed."
            return 1
        fi
    fi
}

function install_pypi_package() {
    activate_python_venv
    for package in $@; do
        if ! is_installed_pypi_package $package; then
            if [ "$USE_VENV" == "310" ];then
                pip install -U $package
            else
                uv pip install -U $package
            fi
        fi
    done
}
function is_installed_package() {
    package_spec="$1"

    # Extract package name and version from the package specification
    package_name=$(echo "$1" | cut -d'=' -f1)
    version=$(echo "$1" | cut -s -d'=' -f2)
    if dpkg -l | grep -qE "^ii  $package_name *$version"; then
        return 0
    else
        echo "$package_name version $version is not installed."
        return 1
    fi
}
install_package() {
    # scripts/install.sh installs scripts/common, services/redis and
    # services/mysql in parallel, so several apt runs would otherwise start at
    # once and all but one fail on the dpkg lock. The failure path below then
    # repairs them out of order, which can leave a package unpacked but
    # unconfigured and run its postinst long after the service's own install
    # script finished — for mariadb-server that postinst re-initializes the
    # datadir and wipes the panel DB user services/mysql/install.sh just
    # created. The lock also covers the is-installed check, so a second run
    # cannot decide to install what the first one is already installing.
    (
        flock 9
        local not_installed_packages=""
        local package

        for package in "$@"; do
            if ! is_installed_package "$package"; then
                # The package is not installed, add it to the list
                not_installed_packages+=" $package"
            fi
        done

        if [ -n "$not_installed_packages" ]; then
            apt install -y --no-install-recommends $not_installed_packages

            # Check if installation failed
            if [ $? -ne 0 ]; then
                apt --fix-broken install -y
                apt update
                #retries for 3 times
                apt install -y $not_installed_packages ||apt install -y $not_installed_packages||apt install -y $not_installed_packages

            fi
        fi
    ) 9>"$(lock_file apt)"
}

function remove_package() {
    for package in $@; do
        if dpkg -l | grep -q "^ii  $package"; then
            with_lock apt apt remove -y --auto-remove "$package"
        fi
    done
}

# --- Admin V2 UI (Vue) -------------------------------------------------------
# The built UI (hiddifypanel/static/admin-v2/) is not in git. Release/beta wheels
# ship it prebuilt (release workflow); every install from source builds it here.

HIDDIFY_PANEL_GIT_URL="https://github.com/hiddify/HiddifyPanel"

function _node_major() {
    command -v node >/dev/null 2>&1 || { echo 0; return; }
    node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0
}


# Node.js for building the admin UI only. The system's node is used when it is new
# enough; otherwise the official prebuilt Node goes into a private directory (no apt
# packages: Ubuntu 22.04's nodejs 12/libnode conflicts with newer node packages).
HIDDIFY_NODE_VERSION="${HIDDIFY_NODE_VERSION:-22.23.3}"
# npm for that private Node (newer than the one bundled with it); needs node ^22.22.2.
HIDDIFY_NPM_VERSION="${HIDDIFY_NPM_VERSION:-12.1.0}"
HIDDIFY_NODE_MIRRORS="${HIDDIFY_NODE_MIRRORS:-https://nodejs.org/dist https://npmmirror.com/mirrors/node}"

function _node_arch() {
    case "$(uname -m)" in
        x86_64 | amd64) echo x64 ;;
        aarch64 | arm64) echo arm64 ;;
        armv7l) echo armv7l ;;
        *) return 1 ;;
    esac
}

function _download_nodejs() {
    local arch dir name mirror tmp
    arch=$(_node_arch) || { error "No prebuilt Node.js for CPU $(uname -m)" >&2; return 1; }
    name="node-v${HIDDIFY_NODE_VERSION}-linux-${arch}"
    dir="$HIDDIFY_DIR/.cache/nodejs/$name"
    if [ -x "$dir/bin/node" ]; then
        echo "$dir"
        return 0
    fi
    install_package curl xz-utils ca-certificates >/dev/null 2>&1
    tmp=$(mktemp -d /var/tmp/hiddify-node.XXXXXX) || return 1
    for mirror in $HIDDIFY_NODE_MIRRORS; do
        warning "Downloading Node.js v${HIDDIFY_NODE_VERSION} from ${mirror} (only to build the admin UI)..." >&2
        if curl -fsSL --retry 2 --connect-timeout 15 -o "$tmp/$name.tar.xz" "$mirror/v${HIDDIFY_NODE_VERSION}/$name.tar.xz" &&
            curl -fsSL --retry 2 --connect-timeout 15 -o "$tmp/SHASUMS256.txt" "$mirror/v${HIDDIFY_NODE_VERSION}/SHASUMS256.txt" &&
            (cd "$tmp" && grep " $name.tar.xz\$" SHASUMS256.txt | sha256sum -c --status); then
            mkdir -p "$(dirname "$dir")"
            rm -rf "$dir"
            if tar -xJf "$tmp/$name.tar.xz" -C "$(dirname "$dir")"; then
                rm -rf "$tmp"
                echo "$dir"
                return 0
            fi
        fi
        warning "Node.js download from ${mirror} failed or did not verify" >&2
        rm -f "$tmp/$name.tar.xz" "$tmp/SHASUMS256.txt"
    done
    rm -rf "$tmp"
    return 1
}

function ensure_nodejs() {
    # Docker images get the UI from the Dockerfile's build stage and must not carry Node.js.
    if [ "${DOCKER_MODE:-}" = "true" ]; then
        error "Not installing Node.js in Docker: the admin UI is built in the Dockerfile's panel-ui stage"
        return 1
    fi
    # vite needs Node >= 18.
    if [ "$(_node_major)" -ge 18 ] && command -v npm >/dev/null 2>&1; then
        return 0
    fi
    local dir
    if ! dir=$(_download_nodejs); then
        error "Could not get Node.js v${HIDDIFY_NODE_VERSION} (tried: ${HIDDIFY_NODE_MIRRORS}). Set HIDDIFY_NODE_MIRRORS to a reachable mirror."
        return 1
    fi
    # Only this shell (the installer) sees it; nothing is installed system-wide.
    export PATH="$dir/bin:$PATH"
    [ "$(_node_major)" -ge 18 ] && command -v npm >/dev/null 2>&1 || return 1
    # Upgrade the private copy's npm once; `-g` installs into $dir (Node's own prefix), not the system.
    if [ -n "$HIDDIFY_NPM_VERSION" ] && [ "$(npm -v 2>/dev/null)" != "$HIDDIFY_NPM_VERSION" ]; then
        warning "Updating npm $(npm -v) -> $HIDDIFY_NPM_VERSION (private Node only)..." >&2
        if ! npm install -g --no-audit --no-fund --loglevel=error "npm@$HIDDIFY_NPM_VERSION"; then
            warning "Could not update npm; building with npm $(npm -v)" >&2
        fi
    fi
    return 0
}

# The UI build needs ~1.2 GB of RAM (Node heap capped at HIDDIFY_UI_BUILD_HEAP_MB; it fails
# below ~900 MB). Small
# VPSes get the build OOM-killed, so add a temporary swap file for the build when
# free RAM + swap is below HIDDIFY_UI_BUILD_MIN_MEM_MB; it is removed right after.
HIDDIFY_UI_BUILD_HEAP_MB="${HIDDIFY_UI_BUILD_HEAP_MB:-2048}"
HIDDIFY_UI_BUILD_MIN_MEM_MB="${HIDDIFY_UI_BUILD_MIN_MEM_MB:-1600}"
_HIDDIFY_UI_SWAPFILE="/var/tmp/hiddify-ui-build.swap"

function _mem_available_mb() {
    awk '/^(MemAvailable|SwapFree):/ {sum += $2} END {print int(sum / 1024)}' /proc/meminfo
}

function _add_build_swap() {
    local have need size_mb disk_mb
    have=$(_mem_available_mb)
    need=$HIDDIFY_UI_BUILD_MIN_MEM_MB
    [ "$have" -ge "$need" ] && return 0
    size_mb=$(( need - have ))
    [ "$size_mb" -lt 1024 ] && size_mb=1024
    [ "$size_mb" -gt 2048 ] && size_mb=2048
    disk_mb=$(df -Pm /var/tmp | awk 'NR==2 {print $4}')
    if [ "${disk_mb:-0}" -lt $(( size_mb + 512 )) ]; then
        warning "Only ${have} MB of memory free and not enough disk for temporary swap; the admin UI build may fail"
        return 0
    fi
    warning "Only ${have} MB of memory free: adding ${size_mb} MB of temporary swap for the admin UI build"
    swapoff "$_HIDDIFY_UI_SWAPFILE" >/dev/null 2>&1
    rm -f "$_HIDDIFY_UI_SWAPFILE"
    if ! { fallocate -l "${size_mb}M" "$_HIDDIFY_UI_SWAPFILE" 2>/dev/null || dd if=/dev/zero of="$_HIDDIFY_UI_SWAPFILE" bs=1M count="$size_mb" status=none; }; then
        rm -f "$_HIDDIFY_UI_SWAPFILE"
        return 0
    fi
    chmod 600 "$_HIDDIFY_UI_SWAPFILE"
    if ! { mkswap "$_HIDDIFY_UI_SWAPFILE" >/dev/null && swapon "$_HIDDIFY_UI_SWAPFILE"; }; then
        # e.g. containers or filesystems that cannot swap: build without it
        rm -f "$_HIDDIFY_UI_SWAPFILE"
    fi
    return 0
}

function _remove_build_swap() {
    [ -f "$_HIDDIFY_UI_SWAPFILE" ] || return 0
    swapoff "$_HIDDIFY_UI_SWAPFILE" >/dev/null 2>&1
    rm -f "$_HIDDIFY_UI_SWAPFILE"
}

# build_panel_ui <panel source dir> [--force]
# Builds the admin UI into <dir>/hiddifypanel/static/admin-v2/ when it is missing
# or older than its sources. No-op for trees without the UI source (e.g. a wheel).
function build_panel_ui() {
    local src="${1%/}" force="${2:-}"
    local ui="$src/hiddifypanel/admin_v2"
    local out="$src/hiddifypanel/static/admin-v2/index.html"
    if [ ! -f "$ui/package.json" ]; then
        return 0
    fi
    if [ "$force" != "--force" ] && [ -f "$out" ] &&
        [ -z "$(find "$ui/src" "$ui/index.html" "$ui/package-lock.json" "$ui/vite.config.ts" "$src/hiddifypanel/translations.i18n" -newer "$out" -print -quit 2>/dev/null)" ]; then
        return 0
    fi
    update_progress "Building..." "Hiddify Panel admin UI (this can take a few minutes)" 30
    ensure_nodejs || { error "Node.js >= 18 is required to build the admin UI"; return 1; }
    # Only clean up node_modules we created: a developer's own checkout keeps theirs.
    local had_node_modules=0
    [ -d "$ui/node_modules" ] && had_node_modules=1
    _add_build_swap
    local rc=0
    (cd "$ui" && npm ci --no-audit --no-fund --loglevel=error &&
        NODE_OPTIONS="--max-old-space-size=$HIDDIFY_UI_BUILD_HEAP_MB ${NODE_OPTIONS:-}" npm run build) || rc=$?
    _remove_build_swap
    if [ "$rc" != 0 ]; then
        if [ "$rc" = 137 ] || dmesg 2>/dev/null | tail -n 20 | grep -qi "killed process.*node"; then
            error "Building the admin UI ran out of memory (needs ~1.2 GB free RAM or swap)"
        else
            error "Building the admin UI failed (see the npm output above)"
        fi
        return 1
    fi
    if [ "$had_node_modules" = 0 ] && [ -z "${HIDDIFY_KEEP_NODE_MODULES:-}" ]; then
        rm -rf "$ui/node_modules"
    fi
    success "Admin UI built"
}

# install_panel_from_git [ref] [pip command]
# Installs the panel from GitHub (develop / tags): clone, build the UI, install.
# `pip install git+...` cannot be used any more: it would install without the UI.
function install_panel_from_git() {
    local ref="${1:-}" pip_cmd="${2:-uv pip}"
    install_package git
    # Outside $HIDDIFY_DIR on purpose: the config renderer (scripts/common/jinja.py) walks
    # $HIDDIFY_DIR for *.j2 and would try to render the panel's own templates.
    local dir
    dir=$(mktemp -d /var/tmp/hiddify-panel-src.XXXXXX) || return 1
    local rc=0
    if ! git clone --quiet --depth 1 ${ref:+--branch "$ref"} "$HIDDIFY_PANEL_GIT_URL" "$dir/src"; then
        error "Could not download the panel source (${ref:-default branch})"
        rc=1
    elif ! build_panel_ui "$dir/src" --force; then
        rc=1
    else
        { $pip_cmd install -U --no-deps --force-reinstall "$dir/src" && $pip_cmd install "$dir/src"; } || rc=$?
    fi
    # Always clean up, also when the download or the UI build failed.
    rm -rf "$dir"
    return $rc
}

function is_installed() {
    if ! command -v "$1" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

function msg_with_hiddify() {
    text=$(
        cat <<END
                                  ▓▓▓
                                ▓▓▓▓▓
                           ▓▓▓       
                         ▓▓▓▓▓  ▓▓▓▓▓
                    ▓▓▓  ▓▓▓▓▓  ▓▓▓▓▓
                 ▓▓▓▓▓▓  ▓▓▓▓▓  ▓▓▓▓▓
                 ▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓
                 ▓▓▓▓▓▓  ▓▓▓▓▓  ▓▓▓▓▓
END
    )
    msg "$text \n\n$1"

}
function center_text() {
    local text="$1"
    local screen_width="$(tput cols)"
    local longest_line_length="$(echo "$text" | awk '{ print length }' | sort -rn | head -1)"
    local padding_width="$(((screen_width - longest_line_length) / 2))"
    while IFS= read -r line; do
        printf "%*s%s\n" $padding_width "" "$line"
    done <<<"$text"
}

function msg() {
    install_package whiptail
    NEWT_COLORS='title=blue, textbox=blue, border=blue, button=black,blue' whiptail --title Hiddify --msgbox "$1" 0 60
    disable_ansii_modes
}


function install_python() {
    # Check if USE_VENV is not set or is empty
    if [ -z "${USE_VENV}" ]; then
        # echo "USE_VENV variable is not set or is empty. Exiting..."
        export USE_VENV=313
    fi
    
    # region install python3.10 system-widely
    rm -rf /usr/lib/python3/dist-packages/blinker*
    

    # endregion

    # region make virtual env
    # Some third-party packages are not compatible with python3.13 eg. grpcio-tools
    # Therefore we still use python3.10 
    # Check if USE_VENV doesn't exist or is true
    # if [ "${USE_VENV}" = true ]; then
        activate_python_venv
    # fi
    # endregion

}
function create_python_venv() {
    if [ "${USE_VENV}" = "310" ]; then
        export venv_path="/opt/hiddify-manager/.venv/"
        if [ ! -d "$venv_path" ]; then
            install_package python3.10-venv
            python3.10 -m venv "$venv_path"
        fi
    else 
        if ! is_installed ${venv_path}/bin/python3.13 ;then
            rm -rf ${venv_path}
            if ! is_installed uv ;then
                curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/bin/ UV_NO_MODIFY_PATH=1 UV_PYTHON_INSTALL_DIR=/usr/local/share/uv sh -s --
            fi
            UV_PYTHON_INSTALL_DIR=/usr/local/share/uv uv venv ${venv_path} --python=3.13
        fi
    fi
    
}
function activate_python_venv() {
    create_python_venv
    if [ -z "$VIRTUAL_ENV" ]; then
        if [ "${USE_VENV}" = "310" ]; then
            export venv_path="/opt/hiddify-manager/.venv"    
        fi
        source "${venv_path}/bin/activate"
    fi
}


function install_python310() {
    # Check if USE_VENV is not set or is empty
   # if [ -z "${USE_VENV}" ]; then
        # echo "USE_VENV variable is not set or is empty. Exiting..."
  #  fi
    export USE_VENV=310
    # region install python3.10 system-widely
    rm -rf /usr/lib/python3/dist-packages/blinker*
    if ! is_installed /opt/hiddify-manager/.venv/bin/python3.10 ;then
        rm -rf /opt/hiddify-manager/.venv/
    fi
    if ! python3.10 --version &>/dev/null; then
        echo "Python 3.10 is not installed. "
        install_package software-properties-common
        add-apt-repository -y ppa:deadsnakes/ppa
    #    sudo apt-get -y remove python*
    fi
    install_package python3.10-dev
    # ln -sf $(which python3.10) /usr/bin/python3
    ln -sf /usr/bin/python3 /usr/bin/python
    if ! pip --version>/dev/null; then
        curl https://bootstrap.pypa.io/get-pip.py | python3.10 -
        python3.10 -m pip install -U pip
    fi
    # endregion

    # region make virtual env
    # Some third-party packages are not compatible with python3.13 eg. grpcio-tools
    # Therefore we still use python3.10 
    # Check if USE_VENV doesn't exist or is true
#    if [ "${USE_VENV}" = "310" ]; then
        activate_python_venv
 #   fi
    # endregion

}
function check_hiddify_panel() {
    if [ "$MODE" != "apply_users" ]; then
        reload_all_configs >/dev/null
        
        if [[ $? != 0 ]]; then
            error "Exception in Hiddify Panel. Please send the log to hiddify@gmail.com"
            echo "4" >log/error.lock
            exit 4
        fi
        echo -e "\n\n"

        bash /opt/hiddify-manager/scripts/status.sh
        bash /opt/hiddify-manager/scripts/common/logo.ico

        install_package qrencode
        center_text "$(qrencode -t utf8 -m 2 $(cat /opt/hiddify-manager/data/current.json | jq -r '.panel_links[]' | tail -n 1))"
        echo ""
        center_text $'\t\033[92mFinished! Thank you for helping to skip filternet.\033[0m'
        
        echo -e "\n"
        echo "Please open the following link in the browser for client setup:"
        cat /opt/hiddify-manager/data/current.json | jq -r '.panel_links[]' | while read -r link; do
            if [[ $link == http://* ]]; then
                link="[insecure] $link"
                error "  $link"
            elif [[ $link =~ ^https://(.+@)?[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ ]]; then
                link="[HTTPS] $link"
                warning "  $link"
            else
                success "  \e]8;;$link\e\\$link\e]8;;\e\\ "
                # success "  $link"
            fi

        done

        # (cd hiddify-panel && python3 -m hiddifypanel admin-links)
        
        for s in hiddify-xray hiddify-core hiddify-nginx hiddify-haproxy hiddify-mysql; do
            [ $s == "hiddify-xray" ] && [ "$(hconfig 'core_type')" != "xray" ] && continue
            [ $s == "hiddify-mysql" ] && [ "$DOCKER_MODE" == "true" ] && continue
            s=${s##*/}
            s=${s%%.*}
            for i in $(seq 1 10); do
                if [[ "$(systemctl is-active "$s")" == "active" ]]; then
                    break
                else
                    if [ $i -eq 10 ]; then
                        error "important service $s is not activated after 10 seconds"
                        error "Installation Failed!"
                        echo "32" >/opt/hiddify-manager/data/log/error.lock
                        exit 32
                    fi
                    warning "an important service $s is not activating yet"
                    sleep 1
                fi
            done
            
        done
    fi
}


function show_progress_window() {
    disable_ansii_modes
    activate_python_venv
    install_pypi_package cli-progress
    python -m cli_progress --title "Hiddify Manager" "$@"
    exit_code=$?
    disable_ansii_modes
    return $exit_code
}


function log_dir() {
    LOG_DIR="/opt/hiddify-manager/data/log/system"
    mkdir -p "$LOG_DIR" >/dev/null 2>&1
    echo $LOG_DIR
}

function log_file() {
    echo "$(log_dir)/${1}.log"
}

# Every mutex in hiddify is an flock on a file under $HIDDIFY_LOCKS. The kernel
# ties the lock to the open file descriptor, so it is released the moment the
# owning process goes away — clean exit, kill -9, crash or power loss alike.
# The .lock files carry no state, so one left behind after a crash never blocks
# a later run: there is nothing to clean up and no staleness timeout to tune.
function lock_file() {
    mkdir -p "$HIDDIFY_LOCKS" >/dev/null 2>&1
    echo "$HIDDIFY_LOCKS/${1}.lock"
}

# Run a command while holding a named lock, waiting for it to become free.
# -o keeps the command from passing the lock on to anything it spawns.
function with_lock() {
    local name="$1"
    shift
    flock -o "$(lock_file "$name")" "$@"
}

# Take a named lock for the lifetime of this shell, or fail fast if it is held.
function set_lock() {
    exec {HIDDIFY_LOCK_FD}>"$(lock_file "$1")"
    if ! flock -n "$HIDDIFY_LOCK_FD"; then
        error "Another installation is running.... Please wait until it finishes."
        exit 12
    fi
}

function remove_lock() {
    [ -n "$HIDDIFY_LOCK_FD" ] || return 0
    # Closing the descriptor is what releases the lock.
    exec {HIDDIFY_LOCK_FD}>&-
    unset HIDDIFY_LOCK_FD
}


function hconfig() {
    local json_file="/opt/hiddify-manager/data/current.json"
    [ ! -f "$json_file" ] && { error "panel config file not found"; return 1; }

    local key=$1
    local essential_vars=$(jq -r '.chconfigs["0"] | to_entries[] | .key' "$json_file")
    for var in $essential_vars; do
        if [ "$key" == "$var" ]; then
            local value=$(jq -r --arg var "$var" '.chconfigs["0"][$var]' "$json_file")
            echo "$value"
            return 0  # Exit the function with success status
        fi
    done

    # If the key is not found, return an error status
    error "Error: Key not found: $key"
    return 1
}
#TODO: check functionality when not using the venv
function hiddify-panel-run() {
    local user=$(whoami)
    local base_command="export HIDDIFY_CFG_PATH='$HIDDIFY_PANEL_CFG_PATH'; cd /opt/hiddify-manager/services/panel/; source ${venv_path}/bin/activate && $@"
    local command=""

    if [ "$user" == "hiddify-panel" ]; then
        command="$base_command"
    else
        command="su hiddify-panel -c \"$base_command\""
    fi

    eval "$command"
}

function hiddify-panel-cli() {
  hiddify-panel-run "python3 -m hiddifypanel $*"
}
# region installer utils
function checkOS() {
    # List of supported distributions
    #supported_distros=("Ubuntu" "Debian" "Fedora" "CentOS" "Arch")
    supported_distros=("Ubuntu")
    # Get the distribution name and version
    if [[ -f "/etc/os-release" ]]; then
        source "/etc/os-release"
        distro_name=$NAME
        distro_version=$VERSION_ID
    else
        echo "Unable to determine distribution."
        exit 1
    fi
    # Check if the distribution is supported
    if [[ " ${supported_distros[@]} " =~ " ${distro_name} " ]]; then
        echo "Your Linux distribution is ${distro_name} ${distro_version}"
        : #no-op command
    else
        # Print error message in red
        echo -e "\e[31mYour Linux distribution (${distro_name} ${distro_version}) is not currently supported.\e[0m"
        exit 1
    fi
    
    # This script only works on Ubuntu 22 and above
    if [ "$(uname)" == "Linux" ]; then
        version_info=$(lsb_release -rs | cut -d '.' -f 1)
        # Check if it's Ubuntu and version is below 22
        if [ "$(lsb_release -is)" == "Ubuntu" ] && [ "$version_info" -lt 22 ]; then
            echo "This script only works on Ubuntu 22 and above"
            exit
        fi
    fi
}
function disable_panel_services() {
    # rm /etc/cron.d/hiddify_usage_update
    # rm /etc/cron.d/hiddify_auto_backup
    # service cron reload >/dev/null 2>&1
    # kill -9 $(pgrep -f 'hiddifypanel update-usage')
    # systemctl restart hiddify-mysql
    echo ""
}

function vercomp () {
    if [[ $1 == $2 ]]
    then
        echo 0
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]//[!0-9]/} > 10#${ver2[i]//[!0-9]/}))
        then
            echo 1
            return 1
        fi
        if ((10#${ver1[i]//[!0-9]/} < 10#${ver2[i]//[!0-9]/}))
        then
            echo 2
            return 2
        fi
    done
    echo 0
    return 0
}


function check_venv_compatibility() {
    package_mode=${1:-release}

    if [ "$package_mode" == "false" ]; then
        package_mode="release"
    fi

    first_release_compatible_venv_version=v10.30

    case "$package_mode" in
        v*)
            # Check if version is greater than or equal to the compatible release version
            
            if [ $(vercomp "$package_mode" "$first_release_compatible_venv_version") == 0 ] || [ $(vercomp "$package_mode" "$first_release_compatible_venv_version") == 1 ]; then
                USE_VENV=310
            fi
        ;;
        develop|dev)
            # Develop is always venv compatible
            USE_VENV=313
        ;;
        beta)
            # Beta is always venv compatible
            USE_VENV=313
        ;;
        release)
            # Get the latest release version
            USE_VENV=313
        ;;
        *)
            echo "Unknown package mode: $package_mode"
            exit 1
        ;;
    esac
}

function hiddify-http-api(){
    api_path=$(jq -r '.api_path // empty' /opt/hiddify-manager/data/current.json 2>/dev/null)
    api_key=$(jq -r '.api_key // empty' /opt/hiddify-manager/data/current.json 2>/dev/null)
    

    if [ -z "$api_path" ] || [ -z "$api_key" ]; then
        echo "invalid config file"
        return 1
    fi
    temp_file=$(mktemp)
    http_status=$(curl -s -o $temp_file -w "%{http_code}" http://localhost:9000/${api_path}/api/v2/$1 --header "Hiddify-API-Key: ${api_key}")
    cat $temp_file
    rm $temp_file
    if [ "$http_status" -ne 200 ];then
        echo $http_status    
        return 1$http_status
    fi
    return 0
}

function is_valid_current_json() {
    jq -e '(.chconfigs["0"] | type == "object") and (.domains | type == "array")' "$1" >/dev/null 2>&1
}

function reload_all_configs(){
    # Fetch into a temp file and replace current.json only when the result is
    # valid: the API reads its credentials from the current copy, and every
    # service script depends on it.
    local cfg=/opt/hiddify-manager/data/current.json
    local tmp
    tmp=$(mktemp "$cfg.XXXXXX") || return 1
    if ! hiddify-http-api admin/all-configs/ >"$tmp" || ! is_valid_current_json "$tmp"; then
        if ! hiddify-panel-cli all-configs >"$tmp" || ! is_valid_current_json "$tmp"; then
            error "Failed to read configs from Hiddify Panel; keeping the previous $cfg"
            rm -f "$tmp"
            return 1
        fi
    fi
    chmod 600 "$tmp"
    mv -f "$tmp" "$cfg" || { rm -f "$tmp"; return 1; }
    cat "$cfg"
}

# Render xray/hiddify-core/haproxy/nginx/dns_proxy configs into $HIDDIFY_GENERATED.
# Prefers the running panel's HTTP API (no extra Python/module load); falls
# back to the CLI (spawns its own interpreter) only if the panel isn't reachable.
function dump_server_configs() {
    # Optional comma-separated cores (xray,hiddify-core,wireguard,telemt). Empty means all.
    local cores="${1:-}"
    local query=""
    [ "$MODE" = "apply_users" ] && query="no_invalidate_cache=1"
    if [ -n "$cores" ]; then
        local enc
        enc=$(printf '%s' "$cores" | jq -sRr @uri)
        query="${query:+$query&}cores=${enc}"
    fi
    [ -n "$query" ] && query="?${query}"
    if hiddify-http-api "admin/dump-server-configs/${query}" >/dev/null; then
        return 0
    fi

    local flags=()
    [ "$MODE" = "apply_users" ] && flags+=(--no-invalidate-cache)
    [ -n "$cores" ] && flags+=(--cores "$cores")
    hiddify-panel-cli dump-server-configs "$HIDDIFY_GENERATED" "${flags[@]}"
}


set_files_in_folder_readable_to_hiddify_common_group() {
    # Ensure paths with spaces or special characters are handled correctly
    file=$1
    find "$file" -type d -exec chmod u+rx,g+rx,o-rwx {} \;  # Directories get rwx for owner, rw- for group
    find "$file" -type f -exec chmod 640 {} \;  # Files get rw- for owner and group
    find "$file" -exec chown :hiddify-common {} \;
    # Handle parent directories if the parent is not "hiddify-manager"
    # Resolve the absolute path of the input
    
    parent=$(realpath "$file")

    while [[ $(basename "$parent") != "hiddify-manager" && "$parent" != "/" ]]; do
        # echo "Setting permissions on $parent"
        chmod u+rx,g+rx "$parent"  # Set permissions on the parent
        chown :hiddify-common "$parent"  # Change ownership to the group
        parent=$(dirname "$parent")  # Move to the next parent directory
    done
}