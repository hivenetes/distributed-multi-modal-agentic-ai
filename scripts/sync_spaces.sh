#!/bin/bash

# Path to rclone config
RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"

# Check if rclone config exists
if [ ! -f "$RCLONE_CONFIG" ]; then
    echo "Error: rclone config not found at $RCLONE_CONFIG"
    exit 1
fi

# Log file for sync operations
LOG_FILE="$HOME/space_sync.log"

# Sync interval in seconds (default: 5 minutes)
SYNC_INTERVAL=300

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to ensure bucket exists
ensure_bucket_exists() {
    local remote=$1
    if ! rclone lsd "$remote" --config "$RCLONE_CONFIG" &>/dev/null; then
        log_message "Bucket for $remote doesn't exist. Creating..."
        rclone mkdir "$remote" --config "$RCLONE_CONFIG"
        if [ $? -eq 0 ]; then
            log_message "Successfully created bucket for $remote"
        else
            log_message "Failed to create bucket for $remote"
            return 1
        fi
    fi
}

# Sync between spaces using the configured remotes
sync_spaces() {
    log_message "Starting continuous sync operation between DigitalOcean Spaces"

    # Ensure destination buckets exist
    ensure_bucket_exists "meridian-spaces-london:/"
    ensure_bucket_exists "meridian-spaces-newyork:/"

    # Only proceed with sync if buckets exist
    if [ $? -eq 0 ]; then
        while true; do
            log_message "Starting sync cycle..."
            
            # Sync AMS3 to LON1
            rclone sync meridian-spaces-amsterdam:meridian-spaces-amsterdam/ meridian-spaces-london:meridian-spaces-london/ --config "$RCLONE_CONFIG" --progress
            if [ $? -eq 0 ]; then
                log_message "Successfully synced AMS3 to LON1"
            else
                log_message "Error syncing AMS3 to LON1"
            fi

            # Sync AMS3 to NYC3
            rclone sync meridian-spaces-amsterdam:meridian-spaces-amsterdam/ meridian-spaces-newyork:meridian-spaces-newyork/ --config "$RCLONE_CONFIG" --progress
            if [ $? -eq 0 ]; then
                log_message "Successfully synced AMS3 to NYC3"
            else
                log_message "Error syncing AMS3 to NYC3"
            fi

            log_message "Sync cycle completed. Waiting for $SYNC_INTERVAL seconds before next sync..."
            sleep $SYNC_INTERVAL
        done
    else
        log_message "Failed to ensure buckets exist. Aborting sync operation."
        exit 1
    fi
}

# Handle script termination gracefully
trap 'log_message "Sync process terminated. Exiting..."; exit 0' SIGINT SIGTERM

# Run the continuous sync operation
sync_spaces 