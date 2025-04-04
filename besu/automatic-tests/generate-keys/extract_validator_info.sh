#!/bin/bash

# Base directory for validator keys
BASE_DIR=${BASE_DIR:-"../../besu-compose"}
NUM_VALIDATORS=${1:-4}
MOCK_MODE=${MOCK_MODE:-false}

# Check if besu CLI is available
if ! command -v besu &> /dev/null && [ "$MOCK_MODE" != "true" ]; then
    echo "Error: Besu CLI is not available. Please install it first."
    exit 1
fi

# Function to generate mock data for testing
generate_mock_data() {
    local key_file=$1
    # Generate deterministic values based on the key file content
    local key_content=$(cat "$key_file")
    # Use the first 40 chars of the key content for address
    local address="0x${key_content:0:40}"
    # Use the full key content (padded if needed) for public key
    local pubkey="${key_content}${key_content:0:$((128-${#key_content}))}"
    echo "$address|$pubkey"
}

# Create a temporary file for the JSON output
TEMP_FILE=$(mktemp)
echo "[" > "$TEMP_FILE"

# Process each validator
for i in $(seq 1 $NUM_VALIDATORS); do
    KEY_FILE="$BASE_DIR/validator$i/key"
    
    if [ ! -f "$KEY_FILE" ]; then
        echo "Error: Key file $KEY_FILE does not exist"
        continue
    fi
    
    if [ "$MOCK_MODE" = "true" ]; then
        # Use mock data for testing
        IFS='|' read -r ADDRESS PUBKEY <<< "$(generate_mock_data "$KEY_FILE")"
    else
        # Create temporary files for command outputs
        ADDRESS_TEMP=$(mktemp)
        PUBKEY_TEMP=$(mktemp)
        
        # Extract Ethereum address using Besu CLI
        besu public-key export-address --node-private-key-file="$KEY_FILE" > "$ADDRESS_TEMP" 2>/dev/null
        
        # Extract public key using Besu CLI
        besu public-key export --node-private-key-file="$KEY_FILE" > "$PUBKEY_TEMP" 2>/dev/null
        
        # Extract just the address (last line of the output)
        ADDRESS=$(tail -n 1 "$ADDRESS_TEMP" | grep -o "0x[a-fA-F0-9]\{40\}")
        
        # Extract just the public key (last line of the output) and remove 0x prefix
        PUBKEY=$(tail -n 1 "$PUBKEY_TEMP" | grep -o "0x[a-fA-F0-9]\{128\}" | sed 's/0x//')
        
        # Clean up temporary files
        rm "$ADDRESS_TEMP" "$PUBKEY_TEMP"
    fi
    
    # Generate enode URL with localhost and different ports
    PORT=$((30303 + i - 1))
    ENODE="enode://${PUBKEY}@127.0.0.1:${PORT}"
    
    # Add to JSON output
    if [ $i -gt 1 ]; then
        echo "," >> "$TEMP_FILE"
    fi
    
    cat >> "$TEMP_FILE" << EOF
  {
    "name": "validator$i",
    "address": "$ADDRESS",
    "enode": "$ENODE"
  }
EOF
    
    echo "Processed validator$i: $ADDRESS"
done

echo "]" >> "$TEMP_FILE"

# Format the JSON output
if command -v jq &> /dev/null; then
    jq '.' "$TEMP_FILE" > "$TEMP_FILE.formatted" && mv "$TEMP_FILE.formatted" "$TEMP_FILE"
fi

# Display the JSON output
echo "Validator Information:"
cat "$TEMP_FILE"

# Save to a file
OUTPUT_FILE="$BASE_DIR/validator_info.json"
cp "$TEMP_FILE" "$OUTPUT_FILE"
echo "Information saved to $OUTPUT_FILE"

# Clean up
rm "$TEMP_FILE" 