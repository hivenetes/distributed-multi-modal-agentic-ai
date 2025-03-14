#!/bin/bash

# Exit on any error
set -e

# Read droplet IPs from terraform output
cd infrastructure
DROPLET_IPS=$(terraform output -json droplet_ips | jq -r '.[]')

# SSH key path
SSH_KEY="$HOME/.ssh/ai"

# Loop through each droplet IP
for IP in $DROPLET_IPS; do
    echo "Deploying to droplet: $IP"
    
    # Copy the .env file
    echo "Copying .env file..."
    scp -i "$SSH_KEY" ../.env root@$IP:/root/
    
    # Copy the docker-compose.production.yml file
    echo "Copying docker-compose.production.yml..."
    scp -i "$SSH_KEY" docker-compose.production.yml root@$IP:/root/docker-compose.yml
    
    # SSH into the droplet and start the container
    echo "Starting containers..."
    ssh -i "$SSH_KEY" root@$IP << 'EOF'
        # Create images directory if it doesn't exist
        mkdir -p images
        
        # Pull the latest image and start containers
        docker compose pull
        docker compose up -d
        
        # Show container status
        docker compose ps
EOF
    
    echo "Deployment completed for $IP"
    echo "----------------------------------------"
done

echo "All deployments completed successfully!" 