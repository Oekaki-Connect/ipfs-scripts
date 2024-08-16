#!/bin/bash

# requires jq
# sudo apt-get install jq

set -e

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

# Function to validate JSON
validate_json() {
    if ! jq empty "$1" 2>/dev/null; then
        echo "Error: Invalid JSON in file $1"
        return 1
    fi
    return 0
}

# Check if zip file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <zipfile>"
    exit 1
fi

ZIP_FILE="$1"
COLLECTION_NAME="${ZIP_FILE%.*}"

# Check if zip file exists
if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: $ZIP_FILE not found!"
    exit 1
fi

# Ensure IPFS daemon is running
check_ipfs_daemon

# Unzip the file
echo "Unzipping $ZIP_FILE..."
unzip -q "$ZIP_FILE" -d "$COLLECTION_NAME"

cd "$COLLECTION_NAME"

# Pin images folder
echo "Pinning images folder..."
IMAGES_CID=$(ipfs add -Qr images)
echo "Images CID: $IMAGES_CID"

# Process JSON files
echo "Processing JSON files..."
for json_file in json/*; do
    number=$(basename "$json_file")
    if ! validate_json "$json_file"; then
        continue
    fi
    
    # Determine the image extension
    image_file=$(find images -name "${number}.*" -print -quit)
    if [ -z "$image_file" ]; then
        echo "Warning: No matching image found for $json_file"
        continue
    fi
    image_ext="${image_file##*.}"
    
    # Update JSON file
    jq --arg cid "$IMAGES_CID" --arg num "$number" --arg ext "$image_ext" '
    if has("image") then
        .image = "ipfs://\($cid)/\($num).\($ext)"
    else
        . | ._temp_image_field = "ipfs://\($cid)/\($num).\($ext)" |
        to_entries |
        map(if .key == "attributes" then
                {"key": "_temp_image_field", "value": ._temp_image_field} + .
            else
                .
            end
        ) |
        from_entries |
        del(._temp_image_field) |
        with_entries(if .key == "_temp_image_field" then .key = "image" else . end)
    end
    ' "$json_file" > "${json_file}.tmp" && mv "${json_file}.tmp" "$json_file"
    
    echo "Updated $json_file"
done

# Pin JSON folder
echo "Pinning JSON folder..."
JSON_CID=$(ipfs add -Qr json)
echo "JSON CID: $JSON_CID"

# Create CIDs file
cat > "${COLLECTION_NAME}_cids.txt" << EOF
# ${COLLECTION_NAME} images
$IMAGES_CID
# ${COLLECTION_NAME} json
$JSON_CID
EOF

echo "CIDs saved to ${COLLECTION_NAME}_cids.txt"

# Print CIDs
cat "${COLLECTION_NAME}_cids.txt"

echo "Processing completed successfully!"