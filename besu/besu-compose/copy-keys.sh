#!/bin/bash

# Script to copy keys from networkFiles to validator directories
# and set appropriate permissions

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get all key directories
KEY_DIRS=($SCRIPT_DIR/networkFiles/keys/0x*)

if [ ${#KEY_DIRS[@]} -ne 4 ]; then
    echo "Error: Expected 4 key directories, found ${#KEY_DIRS[@]}"
    exit 1
fi

# Create validator directories if they don't exist
for i in {1..4}; do
    mkdir -p "$SCRIPT_DIR/validator$i"
done

# Copy keys from networkFiles to validator directories
echo "Copying keys from networkFiles to validator directories..."

# Copy keys for each validator
for i in {1..4}; do
    KEY_DIR="${KEY_DIRS[$((i-1))]}"
    cp "$KEY_DIR/key" "$SCRIPT_DIR/validator$i/key"
    echo "Copied $(basename "$KEY_DIR") key to validator$i/key"
done

# Set permissions to 600 (read/write for owner only)
echo "Setting permissions to 600 for all key files..."
chmod 600 "$SCRIPT_DIR/validator"*/key

# Copy genesis.json to besu-compose directory
echo "Copying genesis.json to main directory..."
cp "$SCRIPT_DIR/networkFiles/genesis.json" "$SCRIPT_DIR/genesis.json"
echo "Copied genesis.json"

echo "Done! All keys have been copied and permissions set."