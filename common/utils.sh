function get_commit_version() {
    COMMIT_URL=$(curl -s https://api.github.com/repos/hiddify/$1/git/refs/heads/main | jq -r .object.url)
    VERSION=$(curl -s $COMMIT_URL | jq -r .committer.date)
    echo ${VERSION:5:11}
}

function get_release_version() {
    # COMMIT_URL=https://api.github.com/repos/hiddify/$1/releases/latest
    # VERSION=$(curl -s --connect-timeout 1 $COMMIT_URL | jq -r .tag_name)
    VERSION=$(curl -sI https://github.com/hiddify/$1/releases/latest | grep -i location | rev | awk -F/ '{print $1}' | rev)
    VERSION=${VERSION//v/}
    echo ${VERSION//$'\r'/}
}

function get_installed_panel_version() {
    echo $(pip3 freeze | grep hiddifypanel | awk -F"==" '{ print $2 }')
}
function get_installed_config_version() {
    cat /opt/hiddify-config/VERSION
}

function get_package_mode() {
    cd /opt/hiddify-config/hiddify-panel
    python3 -m hiddifypanel all-configs | jq -r ".hconfigs.package_mode"
}

function error() {
    echo -e "\033[91m$1\033[0m" >&2
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
