# HyperLedger Besu: Configuring the Docker Compose Environment

### Setting Up the docker-compose.yml File

Now that we have our keys and genesis file, let's create a complete Docker Compose configuration:

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
