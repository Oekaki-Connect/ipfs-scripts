#!/bin/bash

# File containing CIDs, one per line
CID_FILE="cids.txt"

# Function to check if IPFS daemon is running
check_ipfs_daemon() {
    if ! pgrep -x "ipfs" > /dev/null
    then
        echo "IPFS daemon is not running. Starting it now..."
        ipfs daemon &
        sleep 5  # Wait for daemon to start
    else
        echo "IPFS daemon is already running."
    fi
}

# Function to pin a CID
pin_cid() {
    local cid=$1
    if ipfs pin ls | grep -q "$cid"; then
        echo "CID $cid is already pinned."
    else
        echo "Pinning CID $cid..."
        ipfs pin add "$cid"
    fi
}

# Main script
echo "Starting IPFS pinning script..."

# Check and start IPFS daemon if necessary
check_ipfs_daemon

# Check if CID file exists
if [ ! -f "$CID_FILE" ]; then
    echo "Error: $CID_FILE not found!"
    exit 1
fi

# Read CIDs from file and pin them
while IFS= read -r line
do
    # Skip empty lines and comments
    if [[ -n "$line" && ! "$line" =~ ^\s*# ]]; then
        pin_cid "$line"
    fi
done < "$CID_FILE"

echo "Pinning process completed."