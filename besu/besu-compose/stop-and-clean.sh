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