#!/bin/bash
set -euo pipefail

cd "$(dirname -- "$0")"

echo "Initializing Hiddify-Manager Python Environment..."

# Install Python 3.13 if not present
if ! command -v python3.13 >/dev/null 2>&1; then
    echo "Installing Python 3.13..."
    sudo apt-get update
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update
    sudo apt-get install -y python3.13 python3.13-venv
fi

VENV_DIR="$(pwd)/.venv313"

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    sudo python3.13 -m venv "$VENV_DIR"
fi

echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Build deps for bjoern (libev) and mysqlclient (libmysqlclient + python headers).
# Must come before pip install — wheels for these don't ship on PyPI.
sudo apt-get install -y --no-install-recommends \
    python3.13-dev build-essential pkg-config \
    libev-dev libevdev2 default-libmysqlclient-dev >/dev/null

# Install orchestrator requirements
pip install packaging questionary rich jinja2 json5

# Install panel runtime requirements. bjoern is imported directly by
# hiddify-panel/app.py; hiddifypanel ships hiddify-panel-cli on PATH and
# pulls bjoern as a transitive dep, but we still pin bjoern explicitly so a
# partial install can't strand the panel.
pip install --quiet bjoern hiddifypanel || echo "WARN: panel deps install failed; the panel service may not start"

# Execute the python manager.
# PYTHONUNBUFFERED=1 + -u so stdout flushes per-line when piped through
# `tee` (the panel's live-log endpoint polls log/system/<action>.log).
#
# We also tee the output to a per-command log file so the panel's
# AdminLogApi can stream it — and so the same file exists regardless
# of who invoked the action (the panel via commander shim, the menu,
# or `./init.sh foo` from a shell). The shims should NOT tee again;
# centralising it here means one place to fix.
log_file=
case "${1:-}" in
    install|apply-configs|apply-users) log_file="log/system/0-install.log" ;;
    update|upgrade)                    log_file="log/system/update.log"    ;;
    restart)                           log_file="log/system/restart.log"   ;;
    status)                            log_file="log/system/status.log"    ;;
esac

if [ -n "$log_file" ]; then
    mkdir -p "$(dirname "$log_file")"
    # set -o pipefail so a non-zero exit from python propagates through
    # the tee (otherwise tee's success would shadow a real failure).
    set -o pipefail
    env PYTHONUNBUFFERED=1 python3 -u -m hiddify_manager.manager "$@" 2>&1 \
        | stdbuf -oL tee "$log_file"
    exit "${PIPESTATUS[0]}"
fi
exec env PYTHONUNBUFFERED=1 python3 -u -m hiddify_manager.manager "$@"
