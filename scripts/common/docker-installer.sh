#!/bin/bash
# Docker one-liner installer.
#   bash <(curl -fsSL https://i.hiddify.com/docker/release)   # → :latest
#   bash <(curl -fsSL https://i.hiddify.com/docker/beta)      # → :beta
#   bash <(curl -fsSL https://i.hiddify.com/docker/dev)       # → :dev
# Or directly:
#   bash <(curl -fsSL …/scripts/common/docker-installer.sh) beta
#
# Override sources for testing (optional):
#   HIDDIFY_DOCKER_COMPOSE_URL=… HIDDIFY_DOCKER_ENV_URL=… bash docker-installer.sh beta
# Force a git source build instead of pulling :dev:
#   HIDDIFY_DOCKER_BUILD=1 bash docker-installer.sh dev
set -euo pipefail

command -v docker &>/dev/null || curl -fsSL https://get.docker.com | sh

RAW_TAG=${1:-latest}
# i.hiddify.com passes release|beta|dev — map to published ghcr tags.
case "$RAW_TAG" in
    release|stable|latest|"") IMAGE_TAG=latest; MODE=pull ;;
    beta) IMAGE_TAG=beta; MODE=pull ;;
    dev|develop)
        IMAGE_TAG=dev
        if [ "${HIDDIFY_DOCKER_BUILD:-0}" = "1" ]; then MODE=build; else MODE=pull; fi
        ;;
    build|source) IMAGE_TAG=dev; MODE=build ;;
    *) IMAGE_TAG=$RAW_TAG; MODE=pull ;; # e.g. v10.86.0b5
esac

COMPOSE_URL=${HIDDIFY_DOCKER_COMPOSE_URL:-https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/main/docker-compose.yml}
ENV_URL=${HIDDIFY_DOCKER_ENV_URL:-https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/main/docker.env}

if [ -d "hiddify-manager" ]; then
    echo 'Folder "hiddify-manager" already exists. Please change the directory to install with Docker.'
    exit 1
fi

set_env() {
    local key=$1
    local val=$2
    if [ ! -f docker.env ]; then
        touch docker.env
    fi
    if grep -q "^${key}=" docker.env; then
        local escaped
        escaped=$(printf '%s' "$val" | sed -e 's/[&\\]/\\&/g' -e 's/|/\\|/g')
        sed -i "s|^${key}=.*|${key}=${escaped}|" docker.env
    else
        printf '%s=%s\n' "$key" "$val" >> docker.env
    fi
}

activate_image() {
    # Prefer a prebuilt image; never require a local Dockerfile for pull installs.
    # Preserve YAML indentation when commenting/uncommenting keys.
    local tag=$1
    if grep -qE '^[[:space:]]*image:[[:space:]]*ghcr\.io/hiddify/hiddify-manager:' docker-compose.yml; then
        sed -i -E "s|^([[:space:]]*image:[[:space:]]*ghcr\.io/hiddify/hiddify-manager:)[^[:space:]#]+|\1${tag}|" docker-compose.yml
    elif grep -qE '^[[:space:]]*#image:[[:space:]]*ghcr\.io/hiddify/hiddify-manager:' docker-compose.yml; then
        # Uncomment the first matching image line and set the tag (drop trailing inline comments).
        sed -i -E "0,/^[[:space:]]*#image:[[:space:]]*ghcr\.io\/hiddify\/hiddify-manager:/s|^([[:space:]]*)#image:[[:space:]]*ghcr\.io/hiddify/hiddify-manager:[^[:space:]#]*.*|\1image: ghcr.io/hiddify/hiddify-manager:${tag}|" docker-compose.yml
    else
        echo "docker-compose.yml has no hiddify-manager image line; cannot install tag '$tag' without a Dockerfile." >&2
        exit 1
    fi
    sed -i -E 's|^([[:space:]]*)build: \.|\1#build: .|' docker-compose.yml
}

activate_build() {
    sed -i -E \
        -e 's|^([[:space:]]*)image: ghcr\.io/hiddify/hiddify-manager:|\1#image: ghcr.io/hiddify/hiddify-manager:|' \
        -e 's|^([[:space:]]*)#build: \.|\1build: .|' \
        docker-compose.yml
    if ! grep -qE '^[[:space:]]*build: \.' docker-compose.yml; then
        sed -i '/^  hiddifymanager:/a\    build: .' docker-compose.yml
    fi
}

write_passwords() {
    local mysqlpassword redispassword
    mysqlpassword=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c49; echo)
    redispassword=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c49; echo)
    touch docker.env
    set_env MYSQL_PASSWORD "$mysqlpassword"
    set_env REDIS_PASSWORD "$redispassword"
    set_env MYSQL_DATABASE hiddifypanel
    set_env MYSQL_USER hiddifypanel
    set_env SQLALCHEMY_DATABASE_URI "mysql+mysqldb://hiddifypanel:${mysqlpassword}@127.0.0.1:3306/hiddifypanel?charset=utf8mb4"
    set_env REDIS_URI_MAIN "redis://:${redispassword}@127.0.0.1:6379/1"
}

echo "Hiddify Docker install: mode=$MODE image_tag=$IMAGE_TAG (arg=$RAW_TAG)"

if [ "$MODE" = "build" ]; then
    command -v git &>/dev/null || (echo "Installing Git..."; sudo apt-get update && sudo apt-get install -y git)
    git clone --recurse-submodules -b dev https://github.com/hiddify/Hiddify-Manager.git
    cd Hiddify-Manager
    activate_build
    docker compose -f docker-compose.yml build
else
    mkdir hiddify-manager
    cd hiddify-manager
    if [[ "$COMPOSE_URL" == file://* ]]; then
        cp "${COMPOSE_URL#file://}" docker-compose.yml
        cp "${ENV_URL#file://}" docker.env
    else
        wget -q -O docker-compose.yml "$COMPOSE_URL"
        wget -q -O docker.env "$ENV_URL"
    fi
    activate_image "$IMAGE_TAG"
    docker compose pull
fi

write_passwords

if [ "${HIDDIFY_DOCKER_SKIP_UP:-0}" = "1" ]; then
    echo "HIDDIFY_DOCKER_SKIP_UP=1: skipping docker compose up"
    docker compose config >/dev/null
    echo "compose config OK"
    exit 0
fi

docker compose up -d
docker compose logs -f
