#!/bin/bash
#
# First-install bootstrap: download a Hiddify-Manager release archive
# straight from GitHub, extract it to /opt/hiddify-manager, and hand off
# to the python orchestrator (./init.sh upgrade <mode>) for everything
# else.
#
# Replaces the previous flow which downloaded hiddify_installer.sh +
# utils.sh from raw.githubusercontent and ran them — the installer's
# logic now lives in modules/manager_updater + modules/panel_installer.

set -eu

mode="${1:-release}"

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

case "$mode" in
    release)
        archive_url="https://github.com/hiddify/Hiddify-Manager/releases/latest/download/hiddify-manager.zip"
        ;;
    beta)
        echo "beta mode needs an explicit v<tag>; resolve via the GitHub API and pass it." >&2
        exit 2
        ;;
    dev|develop)
        archive_url="https://github.com/hiddify/hiddify-manager/archive/refs/heads/dev.tar.gz"
        ;;
    v*)
        archive_url="https://github.com/hiddify/Hiddify-Manager/releases/download/${mode}/hiddify-manager.zip"
        ;;
    docker)
        echo "docker bootstrap goes through common/docker-installer.sh, not download.sh" >&2
        exit 2
        ;;
    *)
        echo "Unknown mode: $mode (expected release|beta|dev|develop|v<tag>)" >&2
        exit 2
        ;;
esac

target=/opt/hiddify-manager
mkdir -p "$target"
cd "$target"

# Bootstrap needs unzip / tar to be present before init.sh can run.
apt-get install -y --no-install-recommends curl ca-certificates unzip tar >/dev/null

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

case "$archive_url" in
    *.zip)
        echo "Downloading $archive_url..."
        curl -fsSL -o "$tmp/manager.zip" "$archive_url"
        unzip -q -o "$tmp/manager.zip" -d "$target"
        ;;
    *.tar.gz)
        echo "Downloading $archive_url..."
        curl -fsSL -o "$tmp/manager.tar.gz" "$archive_url"
        tar -xzf "$tmp/manager.tar.gz" -C "$target" --strip-components=1
        ;;
esac

cd "$target"
# We just downloaded the source; hand off to `update` (panel install +
# install loop), not `upgrade` (which would re-download the source).
exec ./init.sh update "$mode"
