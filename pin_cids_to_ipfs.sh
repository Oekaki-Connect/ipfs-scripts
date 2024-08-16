#!/bin/bash

# File containing CIDs, one per line
CID_FILE="cids.txt"

# Function to check if IPFS daemon is running
check_ipfs_daemon() {
    if ! pgrep -x "ipfs" > /dev/null
    then
        echo "IPFS daemon is not running. Starting it now..."
        ipfs daemon &
        sleep 10  # Increased wait time for daemon to start
        if ! pgrep -x "ipfs" > /dev/null
        then
            echo "Failed to start IPFS daemon. Please start it manually and try again."
            exit 1
        fi
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
        if ipfs pin add "$cid"; then
            echo "Successfully pinned CID $cid."
        else
            echo "Failed to pin CID $cid. Please check if it's valid."
        fi
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

# Initialize counters
total_cids=0
pinned_cids=0
already_pinned_cids=0
failed_cids=0

# Read CIDs from file and pin them
while IFS= read -r line
do
    # Trim leading and trailing whitespace
    line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    
    # Skip empty lines and comments
    if [[ -n "$line" && ! "$line" =~ ^\s*# ]]; then
        ((total_cids++))
        echo "Processing CID: $line"
        if ipfs pin ls | grep -q "$line"; then
            echo "CID $line is already pinned."
            ((already_pinned_cids++))
        else
            if ipfs pin add "$line"; then
                echo "Successfully pinned CID $line."
                ((pinned_cids++))
            else
                echo "Failed to pin CID $line. Please check if it's valid."
                ((failed_cids++))
            fi
        fi
    fi
done < "$CID_FILE"

# Print summary
echo "Pinning process completed."
echo "Total CIDs processed: $total_cids"
echo "Newly pinned CIDs: $pinned_cids"
echo "Already pinned CIDs: $already_pinned_cids"
echo "Failed to pin CIDs: $failed_cids"