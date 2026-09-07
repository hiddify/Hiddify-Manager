#!/bin/bash

# Check if Docker is installed, if not, install it
command -v docker &>/dev/null || curl -fsSL https://get.docker.com | sh

# Set the default tag if not provided
TAG=${1:-latest}

# Check if the 'hiddify-manager' folder exists
if [ -d "hiddify-manager" ]; then
    echo 'Folder "hiddify-manager" already exists. Please change the directory to install with Docker.'
    exit 1
fi

# Download the docker-compose.yml file or clone the project if it's on dev
if [[ "$TAG" == "develop" || "$TAG" == "dev" ]]; then
    # Check if Git is installed, if not, install it
    command -v git &>/dev/null || (echo "Installing Git..."; sudo apt-get update && sudo apt-get install -y git)
    git clone https://github.com/hiddify/Hiddify-Manager.git -b dev
    cd Hiddify-Manager
    git submodule update --init --recursive
    git submodule update --recursive --remote
    docker compose -f docker-compose.yml build
else
    mkdir hiddify-manager
    cd hiddify-manager
    if [[ "$TAG" == "beta" || "$TAG" == "main" ]]; then
        wget https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/$TAG/docker-compose.yml
        wget https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/$TAG/docker.env
    else
      # Create the 'hiddify-manager' directory
      wget https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/tags/$TAG/docker-compose.yml
      wget https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/tags/$TAG/docker.env
    fi
fi

# Generate random passwords for MySQL and Redis
mysqlpassword=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c49; echo)
redispassword=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c49; echo)

# Update docker-compose.yml with the specified tag and passwords
sed -i "s/hiddify-manager:latest/hiddify-manager:$TAG/g" docker-compose.yml
sed -i "s/redis-strong-password/$redispassword/g" docker.env
sed -i "s/mysql-strong-password/$mysqlpassword/g" docker.env

#temporary for making main version working
sed -i "s/your-strong-password/$redispassword/g" docker.env 
sed -i "s/another-strong-password/$mysqlpassword/g" docker.env


# Start the containers using Docker Compose
docker compose pull
docker compose up -d 

# Follow the logs from the containers
docker compose logs -f
