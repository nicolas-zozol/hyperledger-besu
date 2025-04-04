# Generating Genesis Configuration for QBFT Network

## Overview

This document describes the process of generating the necessary configuration files for setting up a QBFT (Quorum Byzantine Fault Tolerance) network in Hyperledger Besu. The process involves creating three essential files that define the network's initial state and validator configuration.

## Required Files

### 1. validator_info.json

This file contains information about each validator node in the network:

- Validator name (for identification)
- Ethereum address (for transaction signing and block validation)
- Enode URL (for peer-to-peer communication)

Format:

```json
[
  {
    "name": "validator1",
    "address": "0x...",
    "enode": "enode://..."
  },
  ...
]
```

### 2. static-nodes.json

This file lists all validator nodes that should be connected to each other in the network. It contains the enode URLs of all validators, ensuring they can discover and communicate with each other.

Format:

```json
[
  "enode://...",
  "enode://...",
  ...
]
```

### 3. genesis.json

This is the blockchain's initial configuration file that defines:

- Network parameters (chain ID, block time, etc.)
- Consensus mechanism settings (QBFT-specific parameters)
- Initial validator set
- Initial account balances

Format:

```json
{
  "config": {
    "chainId": 2025,
    "qbft": {
      "blockperiodseconds": 2,
      "epochlength": 30000,
      "requesttimeoutseconds": 10
    }
  },
  "extraData": "0x...",
  "alloc": {
    "0x...": {
      "balance": "0xDE0B6B3A7640000"
    }
  }
}
```

## Generation Process

1. **Validator Information Collection**

   - Read validator key files
   - Extract Ethereum addresses
   - Generate enode URLs with appropriate ports
   - Combine information into validator_info.json

2. **Static Nodes Configuration**

   - Extract enode URLs from validator information
   - Create static-nodes.json with all validator enodes

3. **Genesis Configuration**
   - Set network parameters (chain ID, block time, etc.)
   - Configure QBFT consensus parameters
   - Include validator addresses in extraData
   - Set initial account balances
   - Generate genesis.json

## Implementation Considerations

### Key Requirements

- Support for multiple validators
- Proper formatting of Ethereum addresses and enode URLs
- Correct QBFT consensus parameters
- Initial balance allocation for validators

### Error Handling

- Validate input files and parameters
- Check for missing or invalid key files
- Ensure proper JSON formatting
- Verify address and enode URL formats

### Testing

- Verify file generation
- Validate JSON structure
- Check address formats
- Test error handling
- Verify validator count handling

## Usage

The generation process can be implemented in any programming language that supports:

- File system operations
- JSON handling
- Cryptographic functions (for address generation)
- String manipulation

The implementation should focus on:

1. Reading and validating input files
2. Processing validator information
3. Generating properly formatted output files
4. Providing clear error messages
5. Supporting configuration through environment variables

## Output Location

Generated files should be placed in a designated output directory, typically:

```
besu-compose/
  ├── validator_info.json
  ├── static-nodes.json
  └── genesis.json
```

## Configuration Options

The generation process should support:

- Custom chain ID
- Adjustable block time
- Configurable epoch length
- Custom initial balances
- Flexible validator count
- Custom output directory
