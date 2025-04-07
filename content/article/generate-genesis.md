# Generating a Genesis File for a QBFT Network in Hyperledger Besu

When setting up a QBFT (Quorum Byzantine Fault Tolerance) network in Hyperledger Besu, one of the most critical steps is generating the genesis file with the correct `extraData` field. This field contains the validator information and is essential for the QBFT consensus mechanism to function properly.

## The Problem with Hardcoding extraData

In many tutorials and examples, you might see a hardcoded `extraData` field in the genesis file. This approach is problematic because:

1. It's error-prone - manually constructing the `extraData` field is complex
2. It's difficult to maintain - any changes to validators require recalculating the field
3. It's not recommended by the Hyperledger Besu documentation

## The Correct Approach: Using Besu's CLI

The recommended approach is to use Besu's CLI to generate the genesis file with the correct `extraData` field. This ensures that the field is properly formatted and contains the correct validator information.

## Step-by-Step Guide

### 1. Prepare the Configuration File

First, create a configuration file (`qbftConfigFile.json`) that defines the genesis file parameters and the number of validators:

```json
{
  "genesis": {
    "config": {
      "chainId": 1337,
      "berlinBlock": 0,
      "qbft": {
        "blockperiodseconds": 2,
        "epochlength": 30000,
        "requesttimeoutseconds": 4
      }
    },
    "nonce": "0x0",
    "timestamp": "0x58ee40ba",
    "gasLimit": "0x47b760",
    "difficulty": "0x1",
    "mixHash": "0x63746963616c2062797a616e74696e65206661756c7420746f6c6572616e6365",
    "coinbase": "0x0000000000000000000000000000000000000000",
    "alloc": {
      "0x3b251419b64119002d8a3c64f1cd7b19bbefa533": {
        "privateKey": "8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63",
        "comment": "private key and this comment are ignored. In a real chain, the private key should NOT be stored",
        "balance": "0xad78ebc5ac6200000"
      },
      "0x25943f621b10b325bf9023b691b4009861e2e55a": {
        "privateKey": "c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3",
        "comment": "private key and this comment are ignored. In a real chain, the private key should NOT be stored",
        "balance": "90000000000000000000000"
      },
      "0x170af296a1ced3e64250f72a636b19e2dd91bc77": {
        "privateKey": "ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f",
        "comment": "private key and this comment are ignored. In a real chain, the private key should NOT be stored",
        "balance": "90000000000000000000000"
      },
      "0x9cda37edcbf0a5c49cbdfa2b18aa90d6ef98febf": {
        "privateKey": "ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f",
        "comment": "private key and this comment are ignored. In a real chain, the private key should NOT be stored",
        "balance": "90000000000000000000000"
      }
    }
  },
  "blockchain": {
    "nodes": {
      "generate": false, // setting true would create new private keys
      "count": 4
    }
  }
}
```

This configuration file includes:

- The genesis file parameters (chainId, block period, epoch length, etc.)
- The validator addresses and their initial balances
- The number of validators (4 in this case)

### 2. Create a Script to Generate the Genesis File

Create a script (`generate-genesis.sh`) to generate the genesis file using Besu's CLI:

```bash
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

# Check if validator_info.json exists
if [ ! -f validator_info.json ]; then
    echo -e "${RED}Error: validator_info.json not found.${NC}"
    echo "Please run the extract_validator_info.sh script first."
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p output

# Generate the genesis file
echo -e "${YELLOW}Generating genesis file...${NC}"
besu operator generate-blockchain-config --config-file=qbftConfigFile.json --to=output

# Copy the generated files to the current directory
echo -e "${YELLOW}Copying generated files...${NC}"
cp output/genesis.json .
cp -r output/keys .

# Create static-nodes.json from validator_info.json if it doesn't exist
if [ ! -f static-nodes.json ]; then
    echo -e "${YELLOW}Creating static-nodes.json from validator_info.json...${NC}"
    jq -r '.[].enode' validator_info.json > static-nodes.json
fi

echo -e "${GREEN}Genesis file and keys generated successfully!${NC}"
echo "Files are located in the current directory and in the 'output' directory."
echo -e "${YELLOW}Note: The private keys in qbftConfigFile.json are placeholders and will be replaced by the actual keys.${NC}"
```

This script:

- Checks if the required tools (Besu CLI and jq) are available
- Generates the genesis file using Besu's CLI
- Copies the generated files to the current directory
- Creates a static-nodes.json file if it doesn't exist

### 3. Run the Script to Generate the Genesis File

Make the script executable and run it:

```bash
chmod +x generate-genesis.sh
./generate-genesis.sh
```

The script will generate a genesis.json file with the correct `extraData` field:

```json
{
  "config": {
    "chainId": 1337,
    "berlinBlock": 0,
    "qbft": {
      "blockperiodseconds": 2,
      "epochlength": 30000,
      "requesttimeoutseconds": 4
    }
  },
  "nonce": "0x0",
  "timestamp": "0x58ee40ba",
  "gasLimit": "0x47b760",
  "difficulty": "0x1",
  "mixHash": "0x63746963616c2062797a616e74696e65206661756c7420746f6c6572616e6365",
  "coinbase": "0x0000000000000000000000000000000000000000",
  "alloc": {
    "0x3b251419b64119002d8a3c64f1cd7b19bbefa533": {
      "privateKey": "8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63",
      "comment": "private key and this comment are ignored. In a real chain, the private key should NOT be stored",
      "balance": "0xad78ebc5ac6200000"
    },
    "0x25943f621b10b325bf9023b691b4009861e2e55a": {
      "privateKey": "c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3",
      "comment": "private key and this comment are ignored. In a real chain, the private key should NOT be stored",
      "balance": "90000000000000000000000"
    },
    "0x170af296a1ced3e64250f72a636b19e2dd91bc77": {
      "privateKey": "ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f",
      "comment": "private key and this comment are ignored. In a real chain, the private key should NOT be stored",
      "balance": "90000000000000000000000"
    },
    "0x9cda37edcbf0a5c49cbdfa2b18aa90d6ef98febf": {
      "privateKey": "ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f",
      "comment": "private key and this comment are ignored. In a real chain, the private key should NOT be stored",
      "balance": "90000000000000000000000"
    }
  },
  "extraData": "0xe5a00000000000000000000000000000000000000000000000000000000000000000c0c080c0"
}
```

The `extraData` field is now correctly generated by Besu's CLI, ensuring that the QBFT consensus mechanism will function properly.

### 4. Use the Generated Genesis File in Docker Compose

Now you can use the generated genesis.json file in your docker-compose.yml file:

```yaml
services:
  validator1:
    image: hyperledger/besu:latest
    container_name: besu-validator1
    command: >
      --genesis-file=/opt/besu/genesis.json
      --data-path=/opt/besu/data
      --node-private-key-file=/opt/besu/key
      --network-id=2025
      --rpc-http-enabled=true
      --rpc-http-port=8545
      --rpc-http-api=ETH,NET,WEB3,QBFT,TXPOOL,DEBUG
      --host-allowlist=*
      --p2p-port=30303
    volumes:
      - ./validator1/data:/opt/besu/data
      - ./validator1/key:/opt/besu/key
      - ./genesis.json:/opt/besu/genesis.json
      - ./static-nodes.json:/opt/besu/data/static-nodes.json
    ports:
      - "8545:8545"
    networks:
      - besu-network
    restart: unless-stopped
    healthcheck:
      test: curl --fail http://localhost:8545 || exit 1
      interval: 10s
      retries: 5
```

Note that the static-nodes.json file is mounted to `/opt/besu/data/static-nodes.json` in the container, which is the correct location for Besu to find it.

## Conclusion

By using Besu's CLI to generate the genesis file with the correct `extraData` field, you ensure that your QBFT network will function properly. This approach is more reliable and maintainable than hardcoding the `extraData` field.

The script we created automates this process, making it easy to generate the genesis file whenever you need to update your network configuration.
