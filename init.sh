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

# Install orchestrator requirements
pip install packaging questionary rich jinja2 json5

# Install panel runtime requirements. bjoern is imported directly by
# hiddify-panel/app.py; hiddifypanel ships hiddify-panel-cli on PATH and
# pulls bjoern as a transitive dep, but we still pin bjoern explicitly so a
# partial install can't strand the panel.
pip install --quiet bjoern hiddifypanel || echo "WARN: panel deps install failed; the panel service may not start"

# Execute the python manager
python3 -m hiddify_manager.manager "$@"
