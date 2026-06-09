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

VENV_DIR="/opt/hiddify-manager/.venv313"

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    sudo python3.13 -m venv "$VENV_DIR"
fi

echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Install requirements
pip install packaging

# Execute the python manager
python3 hiddify_manager/manager.py "$@"
