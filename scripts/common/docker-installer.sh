#!/bin/bash
set -euo pipefail

# Check if Docker is installed, if not, install it
command -v docker &>/dev/null || curl -fsSL https://get.docker.com | sh

# Set the default tag if not provided (latest | beta | vX.Y.Z | develop|dev)
TAG=${1:-latest}

# Check if the 'hiddify-manager' folder exists
if [ -d "hiddify-manager" ]; then
    echo 'Folder "hiddify-manager" already exists. Please change the directory to install with Docker.'
    exit 1
fi

set_env() {
    # set_env KEY value — rewrite or append KEY= in docker.env (value is written literally)
    local key=$1
    local val=$2
    if [ ! -f docker.env ]; then
        touch docker.env
    fi
    if grep -q "^${key}=" docker.env; then
        # Escape & \ and the sed separator for the replacement side only.
        local escaped
        escaped=$(printf '%s' "$val" | sed -e 's/[&\\]/\\&/g' -e 's/|/\\|/g')
        sed -i "s|^${key}=.*|${key}=${escaped}|" docker.env
    else
        printf '%s=%s\n' "$key" "$val" >> docker.env
    fi
}

# Download the docker-compose.yml file or clone the project if it's on dev
if [[ "$TAG" == "develop" || "$TAG" == "dev" ]]; then
    command -v git &>/dev/null || (echo "Installing Git..."; sudo apt-get update && sudo apt-get install -y git)
    git clone --recurse-submodules -b dev https://github.com/hiddify/Hiddify-Manager.git
    cd Hiddify-Manager
    # Local source build (compose defaults to pulling a prebuilt image).
    sed -i \
        -e 's|^[[:space:]]*image: ghcr.io/hiddify/hiddify-manager:|#image: ghcr.io/hiddify/hiddify-manager:|' \
        -e 's|^[[:space:]]*#build: \.|build: .|' \
        docker-compose.yml
    docker compose -f docker-compose.yml build
else
    mkdir hiddify-manager
    cd hiddify-manager
    wget -q https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/main/docker-compose.yml
    wget -q https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/main/docker.env
    # Ensure we pull a tagged image (compose on main must not require a local Dockerfile).
    if ! grep -qE '^[[:space:]]*image:[[:space:]]*ghcr\.io/hiddify/hiddify-manager:' docker-compose.yml; then
        echo "docker-compose.yml has no hiddify-manager image line; cannot install tag '$TAG' without a Dockerfile."
        echo "Use the develop install, or fix docker-compose.yml to set image: ghcr.io/hiddify/hiddify-manager:$TAG"
        exit 1
    fi
    sed -i -E "s|(image:[[:space:]]*ghcr\.io/hiddify/hiddify-manager:)[^[:space:]#]+|\1${TAG}|" docker-compose.yml
    # Never try to build when only compose+env were downloaded.
    sed -i -E 's|^[[:space:]]*build: \.|#build: .|' docker-compose.yml
    docker compose pull
fi

# Generate random passwords and keep DB/Redis URIs in sync (env_file does not expand ${VAR}).
mysqlpassword=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c49; echo)
redispassword=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c49; echo)

touch docker.env
set_env MYSQL_PASSWORD "$mysqlpassword"
set_env REDIS_PASSWORD "$redispassword"
set_env MYSQL_DATABASE hiddifypanel
set_env MYSQL_USER hiddifypanel
set_env SQLALCHEMY_DATABASE_URI "mysql+mysqldb://hiddifypanel:${mysqlpassword}@127.0.0.1:3306/hiddifypanel?charset=utf8mb4"
set_env REDIS_URI_MAIN "redis://:${redispassword}@127.0.0.1:6379/1"

docker compose up -d
docker compose logs -f
