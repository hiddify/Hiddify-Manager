#!/bin/bash

if [[ "$VER" != "" ]];then
    set -- $VER  $@

fi

echo "$0 input params are $@"


if [[ " $@ " != *"--no-gui"* ]] &&  [[ "$0" == "bash" ]]; then
    echo "This script is deprecated! Please use the following command"
    echo ""
    echo "bash <(curl https://i.hiddify.com/$1)"
    echo ""
    exit 1
fi

echo "Downloading '$@'"

if [[ " $@ " == *" v8 "* ]]; then
    sudo bash -c "$(curl -sLfo- https://raw.githubusercontent.com/hiddify/hiddify-config/main/common/download_install.sh)"
    exit $?
fi


mkdir -p /tmp/hiddify/
chmod 600 /tmp/hiddify/
rm -rf /tmp/hiddify/*


branch="${1:-release}"

if [[ "$branch" == v* ]]; then
    # If input starts with 'v', treat it as a tag
    base_url="https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/tags/$branch/"
elif [[ "$branch" == "beta" ]]; then
    # If input is 'release' or empty, use main
    base_url="https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/beta/"
elif [[ "$branch" == "dev" ]]; then
    # If input is 'release' or empty, use main
    base_url="https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/dev/"
else
    # Otherwise, use the input as a branch name
    base_url="https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/main/"
fi

function _bootstrap_download() {
    local file_name=$1
    local url=$2
    local mirrors=(
        ""
        "https://ghproxy.net/"
        "https://gh-proxy.com/"
    )
    for mirror in "${mirrors[@]}"; do
        for attempt in 1 2 3; do
            echo "Fetching $file_name (mirror='${mirror:-direct}', attempt=$attempt)..."
            if curl -fL --connect-timeout 15 --retry 2 -o "$file_name" "${mirror}${url}"; then
                [[ -s "$file_name" ]] && return 0
                echo "Empty file, retrying..."
            fi
            rm -f "$file_name"
            sleep 3
        done
    done
    echo "ERROR: Failed to download $file_name"
    return 1
}

_bootstrap_download /tmp/hiddify/hiddify_installer.sh "${base_url}common/hiddify_installer.sh" || exit 1
_bootstrap_download /tmp/hiddify/utils.sh "${base_url}common/utils.sh" || exit 1
chmod 700 /tmp/hiddify/*

/tmp/hiddify/hiddify_installer.sh $@
