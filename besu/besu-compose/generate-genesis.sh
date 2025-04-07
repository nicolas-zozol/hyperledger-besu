#!/bin/bash

# 🧠 Requirements
#    - besu CLI installed
#    - jq for JSON processing

# 🧪 Configuration
CONFIG_FILE="qbftConfigFile.json"
OUTPUT_DIR="networkFiles"
DEFAULT_BALANCE="0xDE0B6B3A7640000" # = 1 ETH in wei

# 🎨 Colors
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No color

# 🧼 Cleanup previous files
echo -e "${YELLOW}🧹 Cleaning previous '${OUTPUT_DIR}' folder...${NC}"
rm -rf $OUTPUT_DIR

# 🛠️ Generate blockchain config
echo -e "${BLUE}🚀 Generating genesis and validator keys...${NC}"
besu operator generate-blockchain-config \
  --config-file=$CONFIG_FILE \
  --to=$OUTPUT_DIR \
  --private-key-file-name=key

# 🧾 Genesis path
GENESIS_PATH="$OUTPUT_DIR/genesis.json"

# 💸 Add balances to alloc
echo -e "${BLUE}💰 Injecting balances into 'alloc' section...${NC}"

ALLOC_ENTRIES=""
for NODE_DIR in $OUTPUT_DIR/node-*; do
  ADDRESS_FILE="$NODE_DIR/address"
  if [ -f "$ADDRESS_FILE" ]; then
    ADDRESS=$(cat "$ADDRESS_FILE" | tr -d '\n')
    echo -e "${GREEN}  ➕ Adding $ADDRESS with balance $DEFAULT_BALANCE${NC}"
    ALLOC_ENTRIES+="\"$ADDRESS\": { \"balance\": \"$DEFAULT_BALANCE\" },"
  fi
done

# Remove trailing comma
ALLOC_ENTRIES=${ALLOC_ENTRIES%,}

# 🧩 Inject alloc into genesis.json
# Backup original
cp "$GENESIS_PATH" "$GENESIS_PATH.bak"

# Rebuild with alloc
jq --argjson alloc "{$ALLOC_ENTRIES}" '.alloc = $alloc' "$GENESIS_PATH.bak" > "$GENESIS_PATH"

echo -e "${GREEN}✅ Genesis file updated with validator balances!${NC}"
echo -e "${BLUE}📍 Output located at: ${OUTPUT_DIR}/genesis.json${NC}"
