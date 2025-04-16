#!/bin/bash
SCRIPT_DIR="$(dirname "$BASH_SOURCE")"

if [[ *develop* != $(realpath $SCRIPT_DIR) ]];then 
    SCRIPT_DIR="/opt/hiddify-manager/common/"
fi

source $SCRIPT_DIR/utils.sh
# File to store package information
PACKAGES_LOCK="$SCRIPT_DIR/packages.lock"
CURRENT_PACKAGES="$SCRIPT_DIR/packages.db"
touch $CURRENT_PACKAGES

# Function to calculate file hash
generate_hash() {
    local file=$1
    sha256sum "$file" | awk '{print $1}'
}

# Add a package entry
add_package() {
    local package_name=$1
    local version=$2
    local arch=$3
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
        both) 
            add_package "$package_name" "$version" "amd64" "$4"
            add_package "$package_name" "$version" "arm64" "$4"; 
            return ;;
    esac

    local url=$4

    if [[ -z "$package_name" || -z "$version" || -z "$arch" || -z "$url" ]]; then
        error "Usage: $0 add <package_name> <version> <arch> <url>"
        exit 1
    fi

    # Download the file to calculate the hash
    temp_file="/tmp/${package_name}_${version}_${arch}.tmp"
    wget -q "$url" -O "$temp_file"
    if [[ $? -ne 0 ]]; then
        error "Error downloading file: $url"
        return 1
    fi

    local hash=$(generate_hash "$temp_file")
    rm "$temp_file"

    # Check if the package entry already exists
    existing_entry=$(grep "^$package_name|$version|$arch|" "$PACKAGES_LOCK")
    if [[ -n "$existing_entry" ]]; then
        # Update the existing entry
        sed -i "s|^$package_name\|$version\|$arch\|.*|$package_name\|$version\|$arch\|$url\|$hash|" "$PACKAGES_LOCK"
        echo "Package $package_name version $version for $arch updated successfully."
    else
        # Append package info to the database
        echo "$package_name|$version|$arch|$url|$hash" >> "$PACKAGES_LOCK"
        echo "Package $package_name version $version for $arch added successfully."
    fi
}

# Download a package
download_package() {
    local package_name=$1
    local output_file=$2
    local requested_version=$3

    if [[ -z "$package_name" || -z "$output_file" ]]; then
        error "Usage: $0 download <package_name> <output_file> [<version>]"
        exit 10
    fi

    # Detect architecture
    local arch=$(uname -m)
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
        *)
            error "Unsupported architecture: $arch"
            return 1
            ;;
    esac

    # Find the package entry in the database
    local entry
    local force=0
    [[ "$4" == "force" || "$3" == "force" ]] && force=1
    local existing_version
    existing_version=$(grep -m1 "^$package_name" "$CURRENT_PACKAGES" | cut -d'|' -f2)
    
    if [[ "$requested_version" == "" ]]; then
        requested_version=$(get_latest_version $package_name $arch)
    fi
    
    entry=$(grep "^$package_name|$requested_version" "$PACKAGES_LOCK" | grep "$arch")
    
    if [[ $force == 0 && "$requested_version" == "$existing_version" ]]; then
        return 1
    fi

    if [[ -z "$entry" ]]; then
        error "Package $package_name version $requested_version for $arch not found."
        return 2
    fi

    # Parse the entry
    IFS='|' read -r name version arch url stored_hash <<< "$entry"

    # Download the file
    echo "Downloading package $package_name version $requested_version for $arch... current version is $existing_version"
    local tmp_file=$(mktemp)
    curl -sL -o "$tmp_file" "$url"
    if [[ $? -ne 0 ]]; then
        error "Error downloading file: $url"
        rm "$tmp_file"
        return 3
    fi
    mv "$tmp_file" "$output_file"

    # Verify the hash
    local downloaded_hash=$(generate_hash "$output_file")
    if [[ "$downloaded_hash" != "$stored_hash" ]]; then
        error "Hash mismatch for $output_file. Expected $stored_hash, got $downloaded_hash."
        rm "$output_file"
        return 4
    fi

    echo "Package $package_name version $version downloaded successfully to $output_file."
}
get_latest_version() {
        local package_name=$1
        local arch=$2
        local entry
        entry=$(grep "^$package_name" "$PACKAGES_LOCK" | grep "$arch" | sort -t'|' -k2.1V | tail -n 1)
        local version
        version=${entry#*$package_name|} # remove package name
        version=${version%%|*} # remove the rest
        echo $version
}
# Set the current installed version of a package
set_installed_version() {
    local package_name=$1
    local version=$2
    if [[ -z "$version" ]]; then
        version=$(get_latest_version $package_name)
    fi
    if [[ -z "$package_name" || -z "$version"  ]]; then
        error "Usage: $0 set-installed <package_name> <version>"
        exit 1
    fi

    # Check if the entry already exists in package.lock
    existing_entry=$(grep "^$package_name|" "$CURRENT_PACKAGES")
    if [[ -n "$existing_entry" ]]; then
        # Update the existing entry
        sed -i "s|^$package_name\|.*|$package_name\|$version|" "$CURRENT_PACKAGES"
        echo "Updated installed version of $package_name for $arch to $version."
    else
        # Add a new entry
        echo "$package_name|$version" >> "$CURRENT_PACKAGES"
        echo "Set installed version of $package_name to $version."
    fi
}

if [[ $BASH_SOURCE == "$0" ]]; then
# Main script entry point
case "$1" in
    add)
        add_package "$2" "$3" "$4" "$5"
        ;;
    download)
        download_package "$2" "$3" "$4"
        ;;
    set-installed)
        set_installed_version "$2" "$3"
        ;;
    get-latest-version)
        get_latest_version "$2" "$3"
        ;;
    *)
        error "Usage: $0 {add|download|set-installed} <args>"
        exit 1
        ;;
esac
fi