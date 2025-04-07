#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if Besu CLI is available
if ! command -v besu &> /dev/null; then
    echo -e "${RED}Error: Besu CLI is not available. Please install it first.${NC}"
    echo "You can download it from: https://besu.hyperledger.org/en/stable/HowTo/Get-Started/Install-Binaries/"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not available. Please install it first.${NC}"
    echo "On macOS: brew install jq"
    echo "On Ubuntu/Debian: sudo apt-get install jq"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p output

# Check if validator_info.json exists
if [ ! -f validator_info.json ]; then
    echo -e "${RED}Error: validator_info.json not found.${NC}"
    echo "Please run the extract_validator_info.sh script first."
    exit 1
fi

# Generate the genesis file
echo -e "${YELLOW}Generating genesis file...${NC}"
besu operator generate-blockchain-config --config-file=qbftConfigFile.json --to=output

# Copy the generated files to the current directory
echo -e "${YELLOW}Copying generated files...${NC}"
cp output/genesis.json .
cp -r output/keys .


echo -e "${GREEN}Genesis file and keys generated successfully!${NC}"
echo "Files are located in the current directory and in the 'output' directory."
echo -e "${YELLOW}Note: The private keys in qbftConfigFile.json are placeholders and will be replaced by the actual keys.${NC}" 