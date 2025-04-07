# How to Run Hyperledger Besu with Docker Compose: A Complete Guide

Hyperledger Besu is an enterprise-grade Ethereum client designed for private and permissioned networks. While it can be run directly on a host system, using Docker provides several advantages: isolation, reproducibility, and simplified deployment. In this comprehensive guide, I'll walk you through setting up a multi-validator Hyperledger Besu network using Docker Compose, from initial setup to network verification.

## Chapter 1: Introduction and Project Setup

### What is Hyperledger Besu?

Hyperledger Besu is an open-source Ethereum client developed under the Hyperledger umbrella. It's designed for enterprise use cases and supports both public and private networks. Besu implements the Ethereum protocol and can be configured to use different consensus mechanisms, including Proof of Work (PoW), Proof of Authority (PoA), and Istanbul BFT (IBFT).

### Why Use Docker for Besu Deployment?

Docker provides several benefits for running Hyperledger Besu:

1. **Isolation**: Each validator runs in its own container, preventing conflicts between dependencies or configurations.
2. **Reproducibility**: The same Docker image will run consistently across different environments.
3. **Simplified Deployment**: Docker Compose allows you to define and run multi-container applications with a single command.
4. **Resource Management**: Docker provides built-in resource constraints and monitoring.
5. **Easy Cleanup**: Containers can be easily stopped, removed, and recreated without affecting the host system.

### Overview of the Architecture

In this guide, we'll set up a network with four validators using the QBFT (Quorum Byzantine Fault Tolerance) consensus mechanism. Each validator will:

- Run in its own Docker container
- Have a unique private key for signing blocks
- Have a static IP address on the Docker network
- Connect to other validators via P2P protocol
- Expose an RPC endpoint for client interactions

The network will be configured to use the QBFT consensus mechanism, which requires a minimum of 4 validators for fault tolerance.

### Prerequisites and System Requirements

Before starting, ensure you have the following installed:

- Docker (version 20.10.0 or later)
- Docker Compose (version 2.0.0 or later)
- Git (for cloning repositories)
- Basic understanding of Ethereum concepts and JSON-RPC

For the host system, you'll need:

- At least 4GB of RAM
- 20GB of free disk space
- A Linux-based system (Ubuntu 20.04 LTS recommended) or macOS

### Creating the Project Directory Structure

Let's start by creating a well-organized project structure:

```bash
mkdir -p besu-compose/{validator1,validator2,validator3,validator4}/{data}
cd besu-compose
mkdir -p output/keys
mkdir networkFiles
touch docker-compose.yml
touch stop-and-clean.sh
touch genesis-config.json
chmod +x stop-and-clean.sh
```

This structure creates:

- A main directory for the Docker Compose project
- Subdirectories for each validator with data and key folders
- An output directory for generated files
- A Docker Compose configuration file
- A cleanup script for easy restarts

![Project structure](./images/project-structure.md)

### Understanding the Key Components

Before diving into configuration, let's understand the key components of a Besu network:

1. **Validators**: Nodes that participate in the consensus mechanism by validating and signing blocks.
2. **QBFT Configuration**: Settings specific to the QBFT consensus mechanism..
3. **Private Keys**: Used by validators to sign blocks and transactions. Node addresses are directly derivated from private keys.
4. **Genesis File**: The initial configuration for the blockchain, including network parameters and validator addresses.
5. **Static Nodes**: A list of known peers that validators will attempt to connect to.

### Setting Up QBFT Configuration

In the file genesis-config.json, let's write:

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
    "alloc": {}
  },
  "blockchain": {
    "nodes": {
      "generate": true,
      "count": 4
    }
  }
}
```

The blockchain will have four nodes that aggree to emit a block every 2 seconds on the chainID 1337 (you could pick almost any positive number except maybe 1).

### Setting Up Docker Compose Configuration

Let's create a basic Docker Compose configuration file:

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
      --rpc-http-cors-origins=*
      --sync-mode=FULL
      --p2p-port=30303
      --p2p-host=172.16.239.11
    volumes:
      - ./validator1/data:/opt/besu/data
      - ./validator1/key:/opt/besu/key
      - ./genesis.json:/opt/besu/genesis.json
      - ./static-nodes.json:/opt/besu/data/static-nodes.json
    ports:
      - "8545:8545"
    networks:
      besu-network:
        ipv4_address: 172.16.239.11
    restart: unless-stopped
    healthcheck:
      test: curl --fail http://localhost:8545 || exit 1
      interval: 10s
      retries: 5

  # Similar configuration for validator2, validator3, and validator4
  # with different ports, IPs, and volume mounts:
  # for validator2 command:
  #   --rpc-http-port=8546
  #   --p2p-port=30304
  #   --p2p-host=172.16.239.12
  # Adjust also ports
  #   - "8546:8546"
  # And same for validator3 & validator4

networks:
  besu-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.16.239.0/24
```

This configuration:

- Uses the official Hyperledger Besu Docker image
- Configures each validator with unique ports and IP addresses
- Mounts volumes for data, keys, and configuration files
- Sets up a custom Docker network with static IPs
- Adds healthchecks to monitor validator status

### Creating a Cleanup Script

For easy restarts and cleanup, let's create a script:

```bash
#!/bin/bash

echo "🛑 Stopping all containers..."
docker compose down

echo "🧹 Cleaning data directories..."
for i in {1..4}; do
  echo "   Cleaning validator$i/data"
  rm -rf validator$i/data/*
done

echo "✅ All cleaned up!"
echo "💡 You can now restart the network with:"
echo "   docker compose up -d"
```

This script:

- Stops all running containers
- Cleans up data directories to ensure a fresh start
- Provides instructions for restarting the network

## Chapter 2: Managing Keys and Node Identity

### Understanding Public/Private Key Pairs in Besu

In Hyperledger Besu, each validator needs a private key to sign blocks and transactions. The private key is used to derive a public key, which is then used to create an enode URL for peer discovery.

The relationship between these components is:

- Private Key: Used for signing (kept secret)
- Public Key: Derived from the private key (shared with other nodes)
- Enode URL: Contains the public key, IP address, and port (used for peer discovery)

### Generating Validator Keys

We can now generate keys for Besu validators with the Besu CLI.

First, let's intall it locally:

```bash
brew tap hyperledger/besu
brew install besu
```

Then run the command:

```bash
besu operator generate-blockchain-config \
  --config-file=./genesis-config.json \
  --to=./networkFiles \
  --private-key-file-name=key
```

This command uses the `operator generate-blockchain-config` command to generate keys for 4 validators but also the very precious `genesis.json` file that is declared on `docker-compose.yml` volumes.

The `extraData` field in `genesis.json` is very tricky to generate without this tool.

![Network files](./images/network-files.png)


### Locating and Managing Key Files

After generating keys, you need to ensure they're properly stored and accessible to your validators:

1. **File Location**: Place the `genesis.json` file correctly, as well as each validator's private key in its respective `key` directory:

   ```
   besu-compose/
   ├── validator1/
   │   └── key
   ├── validator2/
   │   └── key
   ├── validator3/
   │   └── key
   └── validator4/
   |   └── key
   └── genesis.json  
   ```

2. **File Permissions**: Ensure the key files have appropriate permissions:

   ```bash
   chmod 600 validator*/key
   ```

Read carefully, but this AI generated nerdy script can help:

```bash
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
```


3. **Volume Mounts**: In your Docker Compose file, check that you did mount each key file to the appropriate location in the container:
   ```yaml
   volumes:
     - ./validator1/key:/opt/besu/key
   ```

### Understanding Enode URLs

An enode URL is a string that uniquely identifies a node in the Ethereum network. It has the following format:

```
enode://<public-key>@<ip-address>:<port>
```

Where:

- `<public-key>` is the public key derived from the validator's private key
- `<ip-address>` is the IP address where the validator is accessible
- `<port>` is the P2P port the validator is listening on

For example:

```
enode://660ae14071c3b4ef70ed5adb11a336f0cb5333fcb283915e33057c64a8dca5406e2f1ea7b0c514688f5748e52d0e70d09147cefe06809f44abca5ef6d6b350a5@172.16.239.11:30303
```

### Extracting Enode URLs from Validator Logs

The most reliable way to get the correct enode URL for each validator is to extract it from the validator's logs after starting the node:

```bash
# Start the validators
docker compose up -d

# Wait a few seconds for them to initialize
sleep 5

# Extract enode URLs from logs
docker compose logs validator1 | grep "Enode URL"
docker compose logs validator2 | grep "Enode URL"
docker compose logs validator3 | grep "Enode URL"
docker compose logs validator4 | grep "Enode URL"
```

This will output something like:

```
Enode URL enode://660ae14071c3b4ef70ed5adb11a336f0cb5333fcb283915e33057c64a8dca5406e2f1ea7b0c514688f5748e52d0e70d09147cefe06809f44abca5ef6d6b350a5@172.16.239.11:30303
```

### Creating a Proper static-nodes.json File

Once you have the enode URLs for all validators, create a `static-nodes.json` file:

```json
[
  "enode://660ae14071c3b4ef70ed5adb11a336f0cb5333fcb283915e33057c64a8dca5406e2f1ea7b0c514688f5748e52d0e70d09147cefe06809f44abca5ef6d6b350a5@172.16.239.11:30303",
  "enode://83a193fdd09f15228dbc3b3510d9883f125afcb9509c880b0866e38ff77c0e267267fbde61315ea91cef98e03eb36699a462a4ce60b7a42b8fec0422ff2a6ce5@172.16.239.12:30304",
  "enode://f78b9740c40cf36e116af5ff94bcdb4821eca06238af111708be371917500beba6b9e828fc4d4fdf5e579c49c82d7a13c952833825db3e07fde60b417595603b@172.16.239.13:30305",
  "enode://1adc5f7675b24390d444833e83792dc65bcccc7bfee463e637230b3be3ace8c9faa9a639f71899c98bcf024224c850734c9d6952daff77292fa96bb2d6a0a343@172.16.239.14:30306"
]
```

This file should be mounted in each validator's container:

```yaml
volumes:
  - ./static-nodes.json:/opt/besu/data/static-nodes.json
```

### Verifying Key Consistency

To ensure your keys are consistent across the network:

1. **Check Private Keys**: Verify that each validator has a unique private key:

   ```bash
   for i in {1..4}; do
     echo "Validator $i key:"
     cat validator$i/key
     echo
   done
   ```

2. **Check Public Keys**: Verify that the public keys in the enode URLs match the private keys:

   ```bash
   # This is a simplified example - in practice, you'd need to derive the public key
   # from the private key and compare it with the enode URL
   for i in {1..4}; do
     echo "Validator $i enode URL:"
     docker compose logs validator$i | grep "Enode URL"
     echo
   done
   ```

3. **Check Connectivity**: Verify that validators can connect to each other:
   ```bash
   for port in {8545..8548}; do
     echo "Checking validator on port $port:"
     curl -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' localhost:$port
     echo
   done
   ```

## Chapter 3: Generating Genesis Configuration

### Understanding the QBFT Consensus Mechanism

QBFT (Quorum Byzantine Fault Tolerance) is a consensus mechanism designed for private Ethereum networks. It's based on the Istanbul BFT algorithm and provides:

- Finality: Transactions are finalized after a certain number of blocks
- Fault Tolerance: The network can continue operating even if some validators are malicious or offline
- Performance: QBFT is designed for high-throughput, low-latency networks

For a network with 4 validators using QBFT:

- At least 3 validators must be online for the network to function
- The network can tolerate 1 malicious validator

### Creating the qbftConfigFile.json

The QBFT configuration file defines parameters specific to the QBFT consensus mechanism:

```json
{
  "validatoraddresses": [
    "0x6f3542ca425b0e30e237980a625714307a78dd59",
    "0xbcd7ecf4d7e33de5c4179009bf5b6256a5335911",
    "0xfba134695e3001a8143f0e7da41f06b07bfca2bb",
    "0x024e644817559e4f5afe26269fb8580613be5548"
  ],
  "blockperiodseconds": 2,
  "epochlength": 30000,
  "requesttimeoutseconds": 4,
  "policy": 0,
  "ceil2nby3": false,
  "testpointdnsenabled": false,
  "generate": false
}
```

Key parameters:

- `validatoraddresses`: List of validator addresses (derived from private keys)
- `blockperiodseconds`: Time between blocks (in seconds)
- `epochlength`: Number of blocks in an epoch
- `requesttimeoutseconds`: Timeout for consensus messages
- `generate`: Set to `false` to use existing keys

### Generating the Genesis File

The genesis file is the initial configuration for the blockchain. For a QBFT network, it needs to include the validator addresses in the `extraData` field.

You can generate a genesis file using the Besu CLI:

```bash
docker run --rm -v $(pwd):/workspace hyperledger/besu:latest operator generate-blockchain-config --config-file=/workspace/qbftConfigFile.json --to=/workspace/output
```

This command:

- Uses the Besu operator to generate a genesis file
- Uses the QBFT configuration file we created
- Outputs the genesis file to the specified directory

The generated genesis file will look something like this:

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
  "alloc": {},
  "extraData": "0xf87aa00000000000000000000000000000000000000000000000000000000000000000f854946f3542ca425b0e30e237980a625714307a78dd5994bcd7ecf4d7e33de5c4179009bf5b6256a533591194fba134695e3001a8143f0e7da41f06b07bfca2bb94024e644817559e4f5afe26269fb8580613be5548c080c0"
}
```

The `extraData` field is RLP-encoded and contains:

1. A fixed header
2. The list of validator addresses

### Verifying Validator Addresses

It's crucial to ensure that the validator addresses in the genesis file match the addresses derived from the private keys used by your validators.

To verify this:

1. **Extract Addresses from Genesis File**:
   The `extraData` field in the genesis file contains the validator addresses. You can decode it using a tool like `rlp` or by examining the Besu logs.

2. **Compare with Validator Addresses**:
   Check that these addresses match the addresses of your validators, which can be found in the validator logs:

   ```bash
   docker compose logs validator1 | grep "Node address"
   ```

3. **Check Consistency**:
   Ensure that all validators are using the correct private keys that correspond to the addresses in the genesis file.

## Chapter 4: Configuring the Docker Compose Environment

### Setting Up the docker-compose.yml File

Now that we have our keys and genesis file, let's create a complete Docker Compose configuration:

```yaml
version: "3.8"

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
      --rpc-http-cors-origins=*
      --sync-mode=FULL
      --p2p-port=30303
      --p2p-host=172.16.239.11
    volumes:
      - ./validator1/data:/opt/besu/data
      - ./validator1/key:/opt/besu/key
      - ./genesis.json:/opt/besu/genesis.json
      - ./static-nodes.json:/opt/besu/data/static-nodes.json
    ports:
      - "8545:8545"
    networks:
      besu-network:
        ipv4_address: 172.16.239.11
    restart: unless-stopped
    healthcheck:
      test: curl --fail http://localhost:8545 || exit 1
      interval: 10s
      retries: 5

  validator2:
    image: hyperledger/besu:latest
    container_name: besu-validator2
    command: >
      --genesis-file=/opt/besu/genesis.json
      --data-path=/opt/besu/data
      --node-private-key-file=/opt/besu/key
      --network-id=2025
      --rpc-http-enabled=true
      --rpc-http-port=8546
      --rpc-http-api=ETH,NET,WEB3,QBFT,TXPOOL,DEBUG
      --host-allowlist=*
      --rpc-http-cors-origins=*
      --sync-mode=FULL
      --p2p-port=30304
      --p2p-host=172.16.239.12
    volumes:
      - ./validator2/data:/opt/besu/data
      - ./validator2/key:/opt/besu/key
      - ./genesis.json:/opt/besu/genesis.json
      - ./static-nodes.json:/opt/besu/data/static-nodes.json
    ports:
      - "8546:8546"
    networks:
      besu-network:
        ipv4_address: 172.16.239.12
    restart: unless-stopped
    healthcheck:
      test: curl --fail http://localhost:8546 || exit 1
      interval: 10s
      retries: 5

  validator3:
    image: hyperledger/besu:latest
    container_name: besu-validator3
    command: >
      --genesis-file=/opt/besu/genesis.json
      --data-path=/opt/besu/data
      --node-private-key-file=/opt/besu/key
      --network-id=2025
      --rpc-http-enabled=true
      --rpc-http-port=8547
      --rpc-http-api=ETH,NET,WEB3,QBFT,TXPOOL,DEBUG
      --host-allowlist=*
      --rpc-http-cors-origins=*
      --sync-mode=FULL
      --p2p-port=30305
      --p2p-host=172.16.239.13
    volumes:
      - ./validator3/data:/opt/besu/data
      - ./validator3/key:/opt/besu/key
      - ./genesis.json:/opt/besu/genesis.json
      - ./static-nodes.json:/opt/besu/data/static-nodes.json
    ports:
      - "8547:8547"
    networks:
      besu-network:
        ipv4_address: 172.16.239.13
    restart: unless-stopped
    healthcheck:
      test: curl --fail http://localhost:8547 || exit 1
      interval: 10s
      retries: 5

  validator4:
    image: hyperledger/besu:latest
    container_name: besu-validator4
    command: >
      --genesis-file=/opt/besu/genesis.json
      --data-path=/opt/besu/data
      --node-private-key-file=/opt/besu/key
      --network-id=2025
      --rpc-http-enabled=true
      --rpc-http-port=8548
      --rpc-http-api=ETH,NET,WEB3,QBFT,TXPOOL,DEBUG
      --host-allowlist=*
      --rpc-http-cors-origins=*
      --sync-mode=FULL
      --p2p-port=30306
      --p2p-host=172.16.239.14
    volumes:
      - ./validator4/data:/opt/besu/data
      - ./validator4/key:/opt/besu/key
      - ./genesis.json:/opt/besu/genesis.json
      - ./static-nodes.json:/opt/besu/data/static-nodes.json
    ports:
      - "8548:8548"
    networks:
      besu-network:
        ipv4_address: 172.16.239.14
    restart: unless-stopped
    healthcheck:
      test: curl --fail http://localhost:8548 || exit 1
      interval: 10s
      retries: 5

networks:
  besu-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.16.239.0/24
```

This configuration:

- Defines four validator services
- Assigns unique ports and IP addresses to each validator
- Mounts the necessary volumes for data, keys, and configuration files
- Sets up a custom Docker network with static IPs
- Adds healthchecks to monitor validator status

### Configuring Network Settings and Static IPs

For a private network, it's important to assign static IP addresses to each validator to ensure consistent connectivity. In our Docker Compose configuration, we:

1. **Define a Custom Network**:

   ```yaml
   networks:
     besu-network:
       driver: bridge
       ipam:
         config:
           - subnet: 172.16.239.0/24
   ```

2. **Assign Static IPs to Each Validator**:

   ```yaml
   networks:
     besu-network:
       ipv4_address: 172.16.239.11
   ```

3. **Configure P2P Host Settings**:
   ```yaml
   command: >
     --p2p-host=172.16.239.11
   ```

This ensures that each validator has a consistent IP address on the Docker network, which is essential for peer discovery.

### Setting Up Volume Mounts

Volume mounts are crucial for persisting data and providing configuration files to the containers:

1. **Data Directory**:

   ```yaml
   volumes:
     - ./validator1/data:/opt/besu/data
   ```

   This mounts the local data directory to the container's data directory, allowing the blockchain data to persist between container restarts.

2. **Private Key**:

   ```yaml
   volumes:
     - ./validator1/key:/opt/besu/key
   ```

   This mounts the private key file to the container, allowing the validator to sign blocks and transactions.

3. **Genesis File**:

   ```yaml
   volumes:
     - ./genesis.json:/opt/besu/genesis.json
   ```

   This mounts the genesis file to the container, providing the initial configuration for the blockchain.

4. **Static Nodes File**:
   ```yaml
   volumes:
     - ./static-nodes.json:/opt/besu/data/static-nodes.json
   ```
   This mounts the static nodes file to the container, providing the list of known peers for peer discovery.

### Configuring P2P Ports and Host Settings

Each validator needs a unique P2P port for peer-to-peer communication:

```yaml
command: >
  --p2p-port=30303
  --p2p-host=172.16.239.11
```

The `--p2p-port` parameter specifies the port that the validator will listen on for P2P connections, while the `--p2p-host` parameter specifies the IP address that the validator will advertise to other nodes.

### Adding Healthchecks

Healthchecks are useful for monitoring the status of your validators:

```yaml
healthcheck:
  test: curl --fail http://localhost:8545 || exit 1
  interval: 10s
  retries: 5
```

This healthcheck:

- Uses `curl` to check if the JSON-RPC endpoint is responding
- Runs every 10 seconds
- Retries up to 5 times before marking the container as unhealthy

### Setting Up RPC Endpoints and API Access

For interacting with the network, each validator exposes a JSON-RPC endpoint:

```yaml
command: >
  --rpc-http-enabled=true
  --rpc-http-port=8545
  --rpc-http-api=ETH,NET,WEB3,QBFT,TXPOOL,DEBUG
  --host-allowlist=*
  --rpc-http-cors-origins=*
```

These parameters:

- Enable the JSON-RPC HTTP endpoint
- Set the port for the JSON-RPC endpoint
- Enable specific JSON-RPC APIs
- Allow connections from any host
- Allow CORS requests from any origin

## Chapter 5: Establishing Node Connectivity

### Understanding the Peer Discovery Process

Hyperledger Besu uses a peer discovery process to find and connect to other nodes in the network. The process involves:

1. **Static Nodes**: Besu first tries to connect to the nodes listed in the `static-nodes.json` file.
2. **Discovery Protocol**: If static nodes are not available, Besu can use the discovery protocol to find other nodes.
3. **Bootnodes**: Besu can also use bootnodes to find other nodes in the network.

For a private network, static nodes are the most reliable method for peer discovery.

### Verifying Peer Connectivity

After starting the network, you can verify that the validators are connecting to each other by checking the peer count of each validator:

```bash
# Check peer count for validator1
curl -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' localhost:8545

# Check peer count for validator2
curl -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' localhost:8546

# Check peer count for validator3
curl -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' localhost:8547

# Check peer count for validator4
curl -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' localhost:8548
```

If everything is configured correctly, each validator should show a peer count of 3 (one for each of the other validators).

### Troubleshooting Common Connectivity Issues

If validators are not connecting to each other, here are some common issues to check:

1. **Static Nodes File**:

   - Ensure the `static-nodes.json` file is correctly formatted
   - Verify that the enode URLs in the file match the actual enode URLs of the validators
   - Check that the file is properly mounted in each validator's container

2. **IP Addresses and Ports**:

   - Verify that the IP addresses and ports in the enode URLs match the actual IP addresses and ports of the validators
   - Check that the `--p2p-host` and `--p2p-port` parameters are correctly set for each validator

3. **Network Configuration**:

   - Ensure that the Docker network is properly configured
   - Check that each validator has a unique IP address on the network
   - Verify that the validators can reach each other on the network

4. **Firewall Settings**:

   - Check if any firewalls are blocking the P2P ports
   - Ensure that the ports are open and accessible

5. **Logs**:
   - Check the logs of each validator for any errors or warnings
   - Look for messages related to peer discovery and connectivity

### Monitoring Network Status

To monitor the status of your network, you can use various JSON-RPC methods:

1. **Peer Count**:

   ```bash
   curl -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' localhost:8545
   ```

2. **Block Number**:

   ```bash
   curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' localhost:8545
   ```

3. **Node Info**:

   ```bash
   curl -X POST --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' localhost:8545
   ```

4. **QBFT Status**:
   ```bash
   curl -X POST --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' localhost:8545
   ```

### Ensuring Proper Consensus Operation

For a QBFT network, it's important to ensure that the consensus mechanism is working correctly:

1. **Validator Set**:

   - Verify that the validator set in the genesis file matches the actual validators in the network
   - Check that each validator is using the correct private key

2. **Block Production**:

   - Monitor block production to ensure that blocks are being produced regularly
   - Check that all validators are signing blocks

3. **Network Synchronization**:
   - Ensure that all validators are synchronized with the same blockchain
   - Check that there are no forks or conflicts

## Chapter 6: Testing and Interacting with the Network

### Starting and Stopping the Network

To start the network:

```bash
docker compose up -d
```

To stop the network:

```bash
docker compose down
```

To restart the network with a clean state:

```bash
./stop-and-clean.sh
docker compose up -d
```

### Verifying the Network is Functioning Correctly

To verify that the network is functioning correctly, you can perform the following checks:

1. **Check Peer Count**:

   ```bash
   for port in {8545..8548}; do
     echo "Checking validator on port $port:"
     curl -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' localhost:$port
     echo
   done
   ```

2. **Check Block Number**:

   ```bash
   for port in {8545..8548}; do
     echo "Checking validator on port $port:"
     curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' localhost:$port
     echo
   done
   ```

3. **Check Validator Set**:
   ```bash
   for port in {8545..8548}; do
     echo "Checking validator on port $port:"
     curl -X POST --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' localhost:$port
     echo
   done
   ```

### Interacting with the Network Using JSON-RPC

You can interact with the network using JSON-RPC calls. Here are some examples:

1. **Get Account Balance**:

   ```bash
   curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x6f3542ca425b0e30e237980a625714307a78dd59", "latest"],"id":1}' localhost:8545
   ```

2. **Send a Transaction**:

   ```bash
   curl -X POST --data '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{"from":"0x6f3542ca425b0e30e237980a625714307a78dd59","to":"0xbcd7ecf4d7e33de5c4179009bf5b6256a5335911","value":"0xde0b6b3a7640000"}],"id":1}' localhost:8545
   ```

3. **Get Transaction Receipt**:
   ```bash
   curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionReceipt","params":["0x123..."],"id":1}' localhost:8545
   ```

### Monitoring Blockchain Status

To monitor the status of the blockchain, you can use various tools and methods:

1. **Block Explorer**:

   - Deploy a block explorer like Blockscout or Etherscan to visualize the blockchain
   - Configure it to connect to one of your validator's JSON-RPC endpoints

2. **Logs**:

   - Monitor the logs of your validators for any errors or warnings
   - Look for messages related to block production and consensus

3. **Metrics**:
   - Enable metrics collection in Besu using the `--metrics-enabled` and `--metrics-port` parameters
   - Use a tool like Prometheus and Grafana to visualize the metrics

### Best Practices for Production Deployment

For a production deployment, consider the following best practices:

1. **Security**:

   - Secure the private keys using a hardware security module (HSM) or a key management service
   - Restrict access to the JSON-RPC endpoints using authentication and authorization
   - Use TLS for secure communication

2. **High Availability**:

   - Deploy multiple validators on different physical machines or cloud providers
   - Use a load balancer to distribute traffic across the validators
   - Implement automatic failover in case of validator failure

3. **Monitoring and Alerting**:

   - Set up comprehensive monitoring and alerting for your validators
   - Monitor system resources, network connectivity, and blockchain status
   - Configure alerts for critical events

4. **Backup and Recovery**:

   - Regularly backup the blockchain data and configuration files
   - Test the recovery process to ensure that you can restore the network in case of failure
   - Document the recovery procedures

5. **Scaling**:
   - Plan for scaling the network as the number of transactions and validators grows
   - Consider using a more powerful hardware for the validators
   - Optimize the network configuration for performance

## Conclusion

Setting up a Hyperledger Besu network with Docker Compose provides a flexible and reproducible environment for developing and testing blockchain applications. By following the steps outlined in this guide, you can create a multi-validator network with QBFT consensus, ensuring that your validators can discover and connect to each other.

The key to success is proper configuration of the keys, genesis file, and static nodes, as well as ensuring that each validator has the correct network settings. With these elements in place, your Besu network will be ready for development, testing, and production deployment.

Remember that blockchain networks are complex systems, and troubleshooting may be required at various stages. By understanding the components and their interactions, you'll be better equipped to diagnose and resolve any issues that arise.

Happy blockchain development with Hyperledger Besu and Docker Compose!
