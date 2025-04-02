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

# Function to get all space remotes from rclone config
get_space_remotes() {
    # Get all remote names that are configured for DigitalOcean Spaces
    grep -A1 "^\[.*\]" "$RCLONE_CONFIG" | grep -B1 "type = s3" | grep "^\[.*\]" | tr -d '[]'
}

# Function to get endpoint region for a remote
get_remote_region() {
    local remote=$1
    local endpoint=$(sed -n "/\[$remote\]/,/\[/p" "$RCLONE_CONFIG" | grep "endpoint" | cut -d'=' -f2 | tr -d ' ')
    echo "$endpoint" | cut -d'.' -f1
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

# Function to sync between two spaces
sync_spaces_pair() {
    local source_remote=$1
    local dest_remote=$2
    local source_region=$3
    local dest_region=$4

    rclone sync "${source_remote}:${source_remote}/" "${dest_remote}:${dest_remote}/" --config "$RCLONE_CONFIG" --progress
    if [ $? -eq 0 ]; then
        log_message "Successfully synced ${source_region} to ${dest_region}"
    else
        log_message "Error syncing ${source_region} to ${dest_region}"
    fi
}

# Sync between spaces using the configured remotes
sync_spaces() {
    log_message "Starting continuous sync operation between DigitalOcean Spaces"

    # Get all configured space remotes
    SPACE_REMOTES=()
    while IFS= read -r remote; do
        SPACE_REMOTES+=("$remote")
    done < <(get_space_remotes)
    
    if [ ${#SPACE_REMOTES[@]} -lt 2 ]; then
        log_message "Error: At least 2 space remotes are required for syncing"
        exit 1
    fi

    # Find the Amsterdam remote to use as source
    SOURCE_REMOTE=""
    for remote in "${SPACE_REMOTES[@]}"; do
        if [[ $(get_remote_region "$remote") == "ams3" ]]; then
            SOURCE_REMOTE=$remote
            break
        fi
    done

    if [ -z "$SOURCE_REMOTE" ]; then
        log_message "Error: No Amsterdam (ams3) remote found for source"
        exit 1
    fi

    # Ensure all destination buckets exist
    for remote in "${SPACE_REMOTES[@]}"; do
        if [ "$remote" != "$SOURCE_REMOTE" ]; then
            ensure_bucket_exists "$remote:/"
        fi
    done

    # Only proceed with sync if buckets exist
    if [ $? -eq 0 ]; then
        while true; do
            log_message "Starting sync cycle..."
            
            # Sync from Amsterdam to all other regions
            for dest_remote in "${SPACE_REMOTES[@]}"; do
                if [ "$dest_remote" != "$SOURCE_REMOTE" ]; then
                    source_region=$(get_remote_region "$SOURCE_REMOTE")
                    dest_region=$(get_remote_region "$dest_remote")
                    sync_spaces_pair "$SOURCE_REMOTE" "$dest_remote" "$source_region" "$dest_region"
                fi
            done

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