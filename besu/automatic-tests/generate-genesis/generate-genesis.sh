#!/bin/bash

# Script to generate genesis.json, static-nodes.json, and validator_info.json
# for a QBFT network with 4 validators

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
BASE_DIR=${BASE_DIR:-"../../besu-compose"}
NUM_VALIDATORS=${NUM_VALIDATORS:-4}
CHAIN_ID=${CHAIN_ID:-2025}
BLOCK_PERIOD_SECONDS=${BLOCK_PERIOD_SECONDS:-2}
EPOCH_LENGTH=${EPOCH_LENGTH:-30000}
REQUEST_TIMEOUT_SECONDS=${REQUEST_TIMEOUT_SECONDS:-10}
VALIDATOR_BALANCE=${VALIDATOR_BALANCE:-"0xDE0B6B3A7640000"} # 1 ETH

# Check if besu CLI is available
if ! command -v besu &> /dev/null; then
    echo -e "${YELLOW}Warning: Besu CLI is not available. Using mock data generation.${NC}"
    MOCK_MODE=true
else
    MOCK_MODE=false
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

# Function to extract validator information
extract_validator_info() {
    local key_file=$1
    local validator_name=$2
    local port=$3
    
    if [ "$MOCK_MODE" = "true" ]; then
        # Use mock data for testing
        IFS='|' read -r ADDRESS PUBKEY <<< "$(generate_mock_data "$key_file")"
    else
        # Create temporary files for command outputs
        ADDRESS_TEMP=$(mktemp)
        PUBKEY_TEMP=$(mktemp)
        
        # Extract Ethereum address using Besu CLI
        besu public-key export-address --node-private-key-file="$key_file" > "$ADDRESS_TEMP" 2>/dev/null
        
        # Extract public key using Besu CLI
        besu public-key export --node-private-key-file="$key_file" > "$PUBKEY_TEMP" 2>/dev/null
        
        # Extract just the address (last line of the output)
        ADDRESS=$(tail -n 1 "$ADDRESS_TEMP" | grep -o "0x[a-fA-F0-9]\{40\}")
        
        # Extract just the public key (last line of the output) and remove 0x prefix
        PUBKEY=$(tail -n 1 "$PUBKEY_TEMP" | grep -o "0x[a-fA-F0-9]\{128\}" | sed 's/0x//')
        
        # Clean up temporary files
        rm "$ADDRESS_TEMP" "$PUBKEY_TEMP"
    fi
    
    # Generate enode URL with localhost and different ports
    ENODE="enode://${PUBKEY}@127.0.0.1:${port}"
    
    # Return the validator info as JSON
    cat << EOF
  {
    "name": "${validator_name}",
    "address": "${ADDRESS}",
    "enode": "${ENODE}"
  }
EOF
    
    # Return the address and enode for later use
    echo "${ADDRESS}|${ENODE}" >&2
}

# Create validator_info.json
echo "Generating validator_info.json..."
echo "[" > "$BASE_DIR/validator_info.json"

# Create static-nodes.json
echo "Generating static-nodes.json..."
echo "[" > "$BASE_DIR/static-nodes.json"

# Create a temporary file for validator addresses and enodes
VALIDATOR_DATA=$(mktemp)

# Process each validator
for i in $(seq 1 $NUM_VALIDATORS); do
    KEY_FILE="$BASE_DIR/validator$i/key"
    PORT=$((30303 + i - 1))
    
    if [ ! -f "$KEY_FILE" ]; then
        echo -e "${RED}Error: Key file $KEY_FILE does not exist${NC}"
        continue
    fi
    
    # Add comma if not the first validator
    if [ $i -gt 1 ]; then
        echo "," >> "$BASE_DIR/validator_info.json"
        echo "," >> "$BASE_DIR/static-nodes.json"
    fi
    
    # Extract validator info and append to validator_info.json
    VALIDATOR_INFO=$(extract_validator_info "$KEY_FILE" "validator$i" "$PORT" 2> >(tee -a "$VALIDATOR_DATA" >/dev/null))
    echo "$VALIDATOR_INFO" >> "$BASE_DIR/validator_info.json"
    
    # Extract enode URL and append to static-nodes.json
    ENODE=$(echo "$VALIDATOR_INFO" | grep -o '"enode": "[^"]*"' | cut -d'"' -f4)
    echo "  \"$ENODE\"" >> "$BASE_DIR/static-nodes.json"
    
    # Get address for display
    ADDRESS=$(echo "$VALIDATOR_INFO" | grep -o '"address": "[^"]*"' | cut -d'"' -f4)
    echo -e "${GREEN}Processed validator$i: $ADDRESS${NC}"
done

echo "]" >> "$BASE_DIR/validator_info.json"
echo "]" >> "$BASE_DIR/static-nodes.json"

# Create genesis.json
echo "Generating genesis.json..."

# Create a temporary file for the extraData field
EXTRA_DATA=$(mktemp)
echo "00000000000000000000000000000000000000000000000000000000000000003b251419b64119002d8a3c64f1cd7b19bbefa53325943f621b10b325bf9023b691b4009861e2e55a170af296a1ced3e64250f72a636b19e2dd91bc779cda37edcbf0a5c49cbdfa2b18aa90d6ef98febf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" > "$EXTRA_DATA"

# Create genesis.json
cat > "$BASE_DIR/genesis.json" << EOF
{
  "config": {
    "chainId": $CHAIN_ID,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "qbft": {
      "blockperiodseconds": $BLOCK_PERIOD_SECONDS,
      "epochlength": $EPOCH_LENGTH,
      "requesttimeoutseconds": $REQUEST_TIMEOUT_SECONDS,
      "policy": 0,
      "ceil2Nby3Block": 0,
      "testnetdns": ""
    },
    "isQuorum": true
  },
  "nonce": "0x0",
  "timestamp": "0x0",
  "extraData": "0x$(cat "$EXTRA_DATA")",
  "gasLimit": "0x8000000",
  "difficulty": "0x1",
  "mixHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "coinbase": "0x0000000000000000000000000000000000000000",
  "alloc": {
EOF

# Add validator balances to genesis.json
FIRST=true
while IFS='|' read -r ADDRESS ENODE; do
    if [ "$FIRST" = "true" ]; then
        FIRST=false
    else
        echo "," >> "$BASE_DIR/genesis.json"
    fi
    cat >> "$BASE_DIR/genesis.json" << EOF
    "$ADDRESS": {
      "balance": "$VALIDATOR_BALANCE"
    }
EOF
done < "$VALIDATOR_DATA"

# Complete genesis.json
cat >> "$BASE_DIR/genesis.json" << EOF
  },
  "number": "0x0",
  "gasUsed": "0x0",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000"
}
EOF

# Clean up
rm "$VALIDATOR_DATA" "$EXTRA_DATA"

# Format JSON files if jq is available
if command -v jq &> /dev/null; then
    echo "Formatting JSON files..."
    for file in "$BASE_DIR"/*.json; do
        jq '.' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    done
fi

echo -e "${GREEN}All files generated successfully!${NC}"
echo -e "Files are located in: $BASE_DIR"
echo -e "  - validator_info.json"
echo -e "  - static-nodes.json"
echo -e "  - genesis.json" 