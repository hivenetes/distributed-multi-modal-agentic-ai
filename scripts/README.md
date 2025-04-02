# Scripts Documentation

This directory contains automation scripts for deployment and data synchronization across DigitalOcean infrastructure.

## Scripts Overview

### `sync_spaces.sh`

This script provides continuous synchronization between DigitalOcean Spaces (object storage) across different regions. It ensures that data is replicated from Amsterdam (AMS3) to London (LON1) and New York (NYC3) regions at regular intervals.

**Key Features:**

- Continuous synchronization with configurable intervals (default: 5 minutes)
- Automatic bucket creation if not exists
- Detailed logging of sync operations
- Graceful termination handling

### `deploy.sh`

This script handles automated deployment of the application to multiple DigitalOcean droplets using Docker containers.

**Key Features:**

- Retrieves droplet IPs from Terraform output
- Cleans up existing Docker containers and images
- Deploys application using Docker Compose
- Handles environment configuration
- Manages DigitalOcean Container Registry authentication

## Prerequisites

### 1. rclone Setup for DigitalOcean Spaces

1. Install rclone:

   ```bash
   # For macOS
   brew install rclone
   
   # For Linux
   curl https://rclone.org/install.sh | sudo bash
   ```

2. Configure rclone for DigitalOcean Spaces:

   ```bash
   rclone config
   ```

3. Add a new remote for each Space with the following settings:
   - Choose "s3" as storage type
   - Set provider as "DigitalOcean Spaces"
   - Enter your Spaces access key and secret key
   - Set endpoint based on region:
     - Amsterdam: `ams3.digitaloceanspaces.com`
     - London: `lon1.digitaloceanspaces.com`
     - New York: `nyc3.digitaloceanspaces.com`

Example rclone config structure:

```conf
[meridian-spaces-amsterdam]
type = s3
provider = DigitalOcean
access_key_id = your_access_key
secret_access_key = your_secret_key
endpoint = ams3.digitaloceanspaces.com

[meridian-spaces-london]
type = s3
provider = DigitalOcean
access_key_id = your_access_key
secret_access_key = your_secret_key
endpoint = lon1.digitaloceanspaces.com

[meridian-spaces-newyork]
type = s3
provider = DigitalOcean
access_key_id = your_access_key
secret_access_key = your_secret_key
endpoint = nyc3.digitaloceanspaces.com
```

### 2. Deployment Prerequisites

1. Terraform installed and configured with DigitalOcean provider
2. SSH key at `$HOME/.ssh/ai` for server access
3. `.env` file in the root directory with required environment variables:

   ```bash
   DO_API_TOKEN=your_digitalocean_api_token
   # Other environment variables...
   ```

4. `docker-compose.production.yml` in the root directory

## Usage

### Sync Spaces

```bash
./scripts/sync_spaces.sh
```

The script will run continuously, syncing data at the specified interval. Use Ctrl+C to stop the sync process gracefully.

### Deploy Application

```bash
./scripts/deploy.sh
```

This will deploy the application to all configured droplets using Docker Compose.

## Logging

- Sync operations are logged to `$HOME/space_sync.log`
- Both scripts provide detailed console output during execution

## Security Notes

- Keep your DigitalOcean API tokens and Space credentials secure
- Never commit sensitive credentials to version control
- Use environment variables for sensitive information
- Ensure proper firewall rules are in place on your droplets 