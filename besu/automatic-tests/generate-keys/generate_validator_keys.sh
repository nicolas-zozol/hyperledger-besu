#!/bin/bash

# Default number of validators if not specified
NUM_VALIDATORS=${1:-4}
BASE_DIR=${BASE_DIR:-"../../besu-compose"}

# Create base directory if it doesn't exist
mkdir -p "$BASE_DIR"

# Generate keys for each validator
for i in $(seq 1 $NUM_VALIDATORS); do
    # Create validator directory and data subdirectory
    mkdir -p "$BASE_DIR/validator$i/data"
    
    # Generate private key using OpenSSL
    openssl rand -hex 32 > "$BASE_DIR/validator$i/key"
    
    echo "Generated key for validator$i"
done

echo "Generated $NUM_VALIDATORS validator keys in $BASE_DIR" 