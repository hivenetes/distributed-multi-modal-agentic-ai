#!/bin/bash

# This script helps authenticate with the DigitalOcean Container Registry
# It should be run on each droplet if you encounter Docker registry authentication issues

# Check if doctl is installed
if ! command -v doctl &> /dev/null; then
    echo "Installing doctl..."
    cd /tmp
    curl -sL https://github.com/digitalocean/doctl/releases/download/v1.92.1/doctl-1.92.1-linux-amd64.tar.gz | tar -xzv
    sudo mv doctl /usr/local/bin
fi

# Check if DO_API_TOKEN is set
if [ -f /root/.env ]; then
    source /root/.env
    if [ -z "$DO_API_TOKEN" ]; then
        echo "DO_API_TOKEN not found in .env file."
        echo "Please enter your DigitalOcean API token:"
        read -r token
        DO_API_TOKEN=$token
        echo "DO_API_TOKEN=$token" >> /root/.env
    fi
else
    echo ".env file not found."
    echo "Please enter your DigitalOcean API token:"
    read -r token
    DO_API_TOKEN=$token
    echo "DO_API_TOKEN=$token" > /root/.env
fi

# Authenticate with DigitalOcean
echo "Authenticating with DigitalOcean..."
doctl auth init -t $DO_API_TOKEN

# Login to DigitalOcean Container Registry
echo "Logging in to DigitalOcean Container Registry..."
doctl registry login

# Set Docker platform preference to linux/amd64
echo "Setting Docker platform preference..."
export DOCKER_DEFAULT_PLATFORM=linux/amd64

echo "Authentication complete. You should now be able to pull images from the registry." 