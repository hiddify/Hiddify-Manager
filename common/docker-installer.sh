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

# Create the 'hiddify-manager' directory
mkdir hiddify-manager
cd hiddify-manager

# Download the docker-compose.yml file
wget https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/main/docker-compose.yml

# Generate random passwords for MySQL and Redis
mysqlpassword=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c49; echo)
redispassword=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c49; echo)

# Update docker-compose.yml with the specified tag and passwords
sed -i "s/hiddify-manager:latest/hiddify-manager:$TAG/g" docker-compose.yml
sed -i "s/REDIS_STRONG_PASS/$redispassword/g" docker-compose.yml
sed -i "s/MYSQL_STRONG_PASS/$mysqlpassword/g" docker-compose.yml

# Start the containers using Docker Compose
docker compose up -d

# Follow the logs from the containers
docker compose logs -f