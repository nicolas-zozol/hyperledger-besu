#!/bin/bash

for i in {1..4}; do
     echo "Validator $i key:"
     cat validator$i/key
     echo
   done

# This is a simplified example - in practice, you'd need to derive the public key
# from the private key and compare it with the enode URL
for i in {1..4}; do
  echo "Validator $i enode URL:"
  docker compose logs validator$i | grep "Enode URL"
  echo
done

for port in {8545..8548}; do
  echo "Checking validator on port $port:"
  curl -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' localhost:$port
  echo
done