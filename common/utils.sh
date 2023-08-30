function get_commit_version() {
    COMMIT_URL=$(curl -s https://api.github.com/repos/hiddify/$1/git/refs/heads/main | jq -r .object.url)
    VERSION=$(curl -s $COMMIT_URL | jq -r .committer.date)
    echo ${VERSION:5:11}
}

function get_release_version() {
    # COMMIT_URL=https://api.github.com/repos/hiddify/$1/releases/latest
    # VERSION=$(curl -s --connect-timeout 1 $COMMIT_URL | jq -r .tag_name)
    curl -sI https://github.com/hiddify/$1/releases/latest | grep -i location | rev | awk -F/ '{print $1}' | rev
    echo ${VERSION//v/}
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
