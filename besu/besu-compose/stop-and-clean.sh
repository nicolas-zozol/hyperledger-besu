#!/bin/bash

# 🎨 Colors
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
RED='\033[1;31m'
NC='\033[0m' # No color

# 🛑 Stop all containers
echo -e "${YELLOW}🛑 Stopping all containers...${NC}"
docker compose down

# ⏳ Wait a moment to ensure all containers are stopped
sleep 2

# 🧹 Clean up data directories
echo -e "${YELLOW}🧹 Cleaning data directories...${NC}"
for i in {1..4}; do
    DATA_DIR="validator${i}/data"
    if [ -d "$DATA_DIR" ]; then
        echo -e "${BLUE}   Cleaning ${DATA_DIR}${NC}"
        rm -rf "$DATA_DIR"
    fi
done

# ✅ Done
echo -e "${GREEN}✅ All cleaned up!${NC}"
echo -e "${BLUE}💡 You can now restart the network with:${NC}"
echo -e "   docker compose up -d" 