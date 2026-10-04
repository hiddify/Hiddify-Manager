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
    git clone https://github.com/hiddify/Hiddify-Manager.git
    cd Hiddify-Manager
    git submodule update --init --recursive
    git submodule update --recursive --remote
    docker compose -f docker-compose.yml build
else
  # Create the 'hiddify-manager' directory
  mkdir hiddify-manager
  cd hiddify-manager
  wget https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/main/docker-compose.yml
  wget https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/main/docke.env
  # Update docker-compose.yml with the specified tag and passwords
  sed -i "s/hiddify-manager:latest/hiddify-manager:$TAG/g" docker-compose.yml  
  docker compose pull
fi

# Generate random passwords for MySQL and Redis
mysqlpassword=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c49; echo)
redispassword=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c49; echo)

# Create an empty docker.env if not existing
touch docker.env

# Lookup variable name for redis password and update its value or append the whole line when required 
if grep -q "^REDIS_PASSWORD=" docker.env; then
    sed -i "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=$redispassword|" docker.env
else
    echo "REDIS_PASSWORD=$redispassword" >> docker.env
fi

# Lookup variable name for MySql password and update its value or append the whole line when required
if grep -q "^MYSQL_PASSWORD=" docker.env; then
    sed -i "s|^MYSQL_PASSWORD=.*|MYSQL_PASSWORD=$mysqlpassword|" docker.env
else
    echo "MYSQL_PASSWORD=$mysqlpassword" >> docker.env
fi

# Start the containers using Docker Compose
docker compose up -d 

# Follow the logs from the containers
docker compose logs -f
