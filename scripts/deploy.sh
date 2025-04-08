#!/bin/bash

# Get server IPs from Terraform output
cd ../infrastructure
DROPLET_IPS=($(terraform output -json droplet_ips | jq -r '.[]'))
cd ../scripts

# Create parallel arrays for names and IPs
server_names=()
for i in "${!DROPLET_IPS[@]}"; do
    server_names[i]="web-$(printf "%02d" $((i+1)))"
done

# Define SSH key
SSH_KEY="$HOME/.ssh/ai"

# Function to deploy to a single server
deploy_to_server() {
    local server_name=$1
    local ip=$2
    
    echo "Deploying to $server_name ($ip)..."
    
    # Clean up Docker system first - safely check if containers exist before stopping
    echo "Cleaning up Docker system..."
    ssh -i "$SSH_KEY" "root@$ip" "docker stop \$(docker ps -a -q) && docker rm \$(docker ps -a -q) && docker rmi \$(docker images -q) -f" || true

    
    # Stop all running containers first
    echo "Stopping all running containers..."
    ssh -i "$SSH_KEY" "root@$ip" "mkdir -p /root/app && cd /root/app && docker compose down" || true
    
    # Stop any remaining containers using port 7860 - safely check if containers exist
    echo "Stopping containers on port 7860..."
    ssh -i "$SSH_KEY" "root@$ip" "containers=\$(docker ps -q --filter publish=7860); if [ -n \"\$containers\" ]; then docker stop \$containers; fi" || true
    
    # Create app directory if it doesn't exist
    ssh -i "$SSH_KEY" "root@$ip" "mkdir -p /root/app"
    if [ $? -ne 0 ]; then
        echo "Failed to create app directory on $server_name"
        return 1
    fi
    
    # Copy .env and docker-compose.production.yml files
    # Create temporary .env file with OTEL_RESOURCE_ATTRIBUTES
    cp ../.env /tmp/.env-$server_name.tmp
    echo "" >> /tmp/.env-$server_name.tmp
    echo "HOSTNAME=$server_name" >> /tmp/.env-$server_name.tmp
    echo "OTEL_RESOURCE_ATTRIBUTES=service.instance.id=$server_name" >> /tmp/.env-$server_name.tmp
    # Copy the temporary .env file
    scp -i "$SSH_KEY" /tmp/.env-$server_name.tmp "root@$ip:/root/app/.env"
    if [ $? -ne 0 ]; then
        echo "Failed to copy .env file to $server_name"
        rm /tmp/.env-$server_name.tmp
        return 1
    fi
    rm /tmp/.env-$server_name.tmp
    
    scp -i "$SSH_KEY" ../docker-compose.observability-cloud.yml "root@$ip:/root/app/docker-compose.yml"
    if [ $? -ne 0 ]; then
        echo "Failed to copy docker-compose file to $server_name"
        return 1
    fi
    
    # Login to DigitalOcean container registry using DO_API_TOKEN from .env
    ssh -i "$SSH_KEY" "root@$ip" "cd /root/app && export \$(cat .env | grep DO_API_TOKEN) && docker login registry.digitalocean.com -u \$DO_API_TOKEN -p \$DO_API_TOKEN"
    if [ $? -ne 0 ]; then
        echo "Failed to login to DigitalOcean container registry on $server_name"
        return 1
    fi
    
    # Run docker compose up with the production configuration
    ssh -i "$SSH_KEY" "root@$ip" "cd /root/app && docker compose up -d"
    if [ $? -ne 0 ]; then
        echo "Failed to run docker compose on $server_name"
        return 1
    fi
    
    echo "Successfully deployed to $server_name"
    return 0
}

# Main deployment loop
echo "Starting deployment to all servers..."

for i in "${!DROPLET_IPS[@]}"; do
    deploy_to_server "${server_names[i]}" "${DROPLET_IPS[i]}"
    if [ $? -ne 0 ]; then
        echo "Deployment failed for ${server_names[i]}"
    fi
done

echo "Deployment process completed" 
