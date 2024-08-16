#!/bin/bash

set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
required_commands=("jq" "unzip" "ipfs")
missing_commands=()

for cmd in "${required_commands[@]}"; do
    if ! command_exists "$cmd"; then
        missing_commands+=("$cmd")
    fi
done

if [ ${#missing_commands[@]} -ne 0 ]; then
    echo "Error: The following required commands are missing:"
    for cmd in "${missing_commands[@]}"; do
        echo "  - $cmd"
    done
    echo "Please install these commands and try again."
    echo "You can usually install them using your package manager:"
    echo "  For Ubuntu/Debian: sudo apt-get install ${missing_commands[*]}"
    echo "  For macOS with Homebrew: brew install ${missing_commands[*]}"
    exit 1
fi

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
IMAGES_CID=$(ipfs add -Qr --cid-version=1 images)
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
JSON_CID=$(ipfs add -Qr --cid-version=1 json)
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

# Verify that CIDs are pinned
echo "Verifying that CIDs are pinned..."
PINNED_CIDS=$(ipfs pin ls --type=recursive | awk '{print $1}')

for CID in $IMAGES_CID $JSON_CID; do
    if echo "$PINNED_CIDS" | grep -q "$CID"; then
        echo "✅ CID $CID is pinned successfully."
    else
        echo "❌ Warning: CID $CID is not pinned!"
    fi
done

echo "Processing completed successfully!"