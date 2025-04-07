# Creating a Proper static-nodes.json for Hyperledger Besu

When setting up a Hyperledger Besu network with multiple validators, one of the most critical configuration files is `static-nodes.json`. This file tells each validator which other nodes to connect to, enabling the peer-to-peer network to form correctly. In this article, I'll explain how to create a proper `static-nodes.json` file that ensures all validators can discover and connect to each other.

## Why static-nodes.json Matters

Hyperledger Besu uses a peer-to-peer network protocol to communicate between nodes. For a private network, you need to explicitly tell each node which other nodes to connect to. The `static-nodes.json` file serves this purpose by listing the enode URLs of all validators in your network.

Without a properly configured `static-nodes.json`, your validators won't be able to find each other, resulting in a network that doesn't function correctly. Each validator will be isolated, unable to reach consensus or process transactions.

## Understanding Enode URLs

An enode URL in Besu has the following format:

```
enode://<public-key>@<ip-address>:<port>
```

Where:

- `<public-key>` is the public key derived from the validator's private key
- `<ip-address>` is the IP address where the validator is accessible
- `<port>` is the P2P port the validator is listening on

## Step-by-Step Guide to Creating static-nodes.json

### 1. Start Your Validators

First, start your validators with the correct configuration. Each validator should have:

- A unique private key
- A unique IP address
- A unique P2P port

For example, in a Docker Compose setup, you might configure each validator with:

```yaml
command: >
  --p2p-port=30303
  --p2p-host=172.16.239.11
```

### 2. Extract the Enode URLs

After starting your validators, you need to extract the enode URLs from each validator's logs. The easiest way to do this is to check the logs of each validator:

```bash
docker compose logs validator1 | grep "Enode URL"
```

This will output something like:

```
Enode URL enode://660ae14071c3b4ef70ed5adb11a336f0cb5333fcb283915e33057c64a8dca5406e2f1ea7b0c514688f5748e52d0e70d09147cefe06809f44abca5ef6d6b350a5@172.16.239.11:30303
```

Repeat this for each validator in your network.

### 3. Create the static-nodes.json File

Create a file named `static-nodes.json` with the following structure:

```json
[
  "enode://<public-key-1>@<ip-1>:<port-1>",
  "enode://<public-key-2>@<ip-2>:<port-2>",
  "enode://<public-key-3>@<ip-3>:<port-3>",
  "enode://<public-key-4>@<ip-4>:<port-4>"
]
```

Replace the placeholders with the actual enode URLs you extracted from the logs.

### 4. Mount the File in Each Validator

Make sure each validator has access to the `static-nodes.json` file. In a Docker Compose setup, you would mount it like this:

```yaml
volumes:
  - ./static-nodes.json:/opt/besu/data/static-nodes.json
```

Note that the path inside the container should match your `--data-path` parameter.

### 5. Restart Your Network

After creating and mounting the `static-nodes.json` file, restart your network:

```bash
docker compose down
docker compose up -d
```

### 6. Verify Connectivity

Check that your validators are connecting to each other by querying the peer count of each validator:

```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' localhost:8545
```

If everything is configured correctly, each validator should show a peer count equal to the number of other validators in your network.

## Common Pitfalls to Avoid

1. **Incorrect IP Addresses**: Make sure the IP addresses in your enode URLs match the actual IP addresses of your validators. In a Docker network, these should be the internal Docker network IPs.

2. **Port Mismatches**: Ensure the ports in your enode URLs match the `--p2p-port` parameter you specified for each validator.

3. **Public Key Mismatches**: The public keys in your enode URLs must match the private keys you're using for each validator. If you're using pre-generated keys, make sure you're using the correct ones.

4. **Missing Mounts**: Ensure the `static-nodes.json` file is properly mounted in each validator's container.

5. **Self-References**: Each validator should not include its own enode URL in its `static-nodes.json` file. While this won't break anything, it's inefficient as each node will try to connect to itself.

## Conclusion

A properly configured `static-nodes.json` file is essential for a functioning Hyperledger Besu network. By following these steps, you can ensure that all your validators can discover and connect to each other, enabling your network to reach consensus and process transactions.

Remember that the key to success is extracting the correct enode URLs from your validators' logs and ensuring that each validator has access to the complete list of other validators in the network.
