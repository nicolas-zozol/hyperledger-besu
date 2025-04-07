
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
