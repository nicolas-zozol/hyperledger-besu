#!/bin/bash

# Test script for generate-genesis.sh

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test directory
TEST_DIR="test_besu_compose"
SCRIPT_PATH="./generate-genesis.sh"
TOTAL_TESTS=0
PASSED_TESTS=0

# Function to run a test and track results
run_test() {
    local test_name=$1
    local test_cmd=$2
    ((TOTAL_TESTS++))
    
    echo "Running test: $test_name"
    if eval "$test_cmd"; then
        echo -e "${GREEN}Test passed: $test_name${NC}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}Test failed: $test_name${NC}"
        return 1
    fi
}

# Setup test environment
setup() {
    # Clean up any previous test data
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    
    # Generate test keys
    for i in {1..4}; do
        mkdir -p "$TEST_DIR/validator$i"
        openssl rand -hex 32 > "$TEST_DIR/validator$i/key"
    done
}

# Test 1: Check if script exists and is executable
test_script_exists() {
    [ -x "$SCRIPT_PATH" ]
}

# Test 2: Check if script generates validator_info.json
test_validator_info_json() {
    MOCK_MODE=true BASE_DIR="$TEST_DIR" "$SCRIPT_PATH" > /dev/null 2>&1
    if [ ! -f "$TEST_DIR/validator_info.json" ]; then
        echo "validator_info.json not found"
        return 1
    fi
    
    # Check if the file contains the expected number of validators
    local count
    count=$(grep -c '"name": *"validator' "$TEST_DIR/validator_info.json" || echo "0")
    if [ "$count" -ne 4 ]; then
        echo "Expected 4 validators, found $count"
        return 1
    fi
    
    # Check if each validator has name, address, and enode
    for i in {1..4}; do
        if ! grep -q "\"name\": *\"validator$i\"" "$TEST_DIR/validator_info.json"; then
            echo "Missing validator$i name"
            return 1
        fi
        if ! grep -q "\"address\": *\"0x[a-fA-F0-9]\{40\}\"" "$TEST_DIR/validator_info.json"; then
            echo "Invalid address format for validator$i"
            return 1
        fi
        if ! grep -q "\"enode\": *\"enode://[a-fA-F0-9]\{128\}@127\.0\.0\.1:3030[3-6]\"" "$TEST_DIR/validator_info.json"; then
            echo "Invalid enode format for validator$i"
            return 1
        fi
    done
    
    return 0
}

# Test 3: Check if script generates static-nodes.json
test_static_nodes_json() {
    MOCK_MODE=true BASE_DIR="$TEST_DIR" "$SCRIPT_PATH" > /dev/null 2>&1
    if [ ! -f "$TEST_DIR/static-nodes.json" ]; then
        echo "static-nodes.json not found"
        return 1
    fi
    
    # Check if the file contains the expected number of enode URLs
    local count
    count=$(grep -c "enode://" "$TEST_DIR/static-nodes.json" || echo "0")
    if [ "$count" -ne 4 ]; then
        echo "Expected 4 enode URLs, found $count"
        return 1
    fi
    
    # Check if each enode URL is properly formatted
    for i in {1..4}; do
        if ! grep -q "enode://[a-fA-F0-9]\{128\}@127\.0\.0\.1:3030[3-6]" "$TEST_DIR/static-nodes.json"; then
            echo "Invalid enode URL format"
            return 1
        fi
    done
    
    return 0
}

# Test 4: Check if script generates genesis.json
test_genesis_json() {
    MOCK_MODE=true BASE_DIR="$TEST_DIR" "$SCRIPT_PATH" > /dev/null 2>&1
    if [ ! -f "$TEST_DIR/genesis.json" ]; then
        echo "genesis.json not found"
        return 1
    fi
    
    # Check if the file contains the expected chain ID
    if ! grep -q "\"chainId\": *2025" "$TEST_DIR/genesis.json"; then
        echo "Expected chainId 2025 not found"
        return 1
    fi
    
    # Check if the file contains the expected block period
    if ! grep -q "\"blockperiodseconds\": *2" "$TEST_DIR/genesis.json"; then
        echo "Expected blockperiodseconds 2 not found"
        return 1
    fi
    
    # Check if the file contains the expected epoch length
    if ! grep -q "\"epochlength\": *30000" "$TEST_DIR/genesis.json"; then
        echo "Expected epochlength 30000 not found"
        return 1
    fi
    
    # Check if the file contains the expected request timeout
    if ! grep -q "\"requesttimeoutseconds\": *10" "$TEST_DIR/genesis.json"; then
        echo "Expected requesttimeoutseconds 10 not found"
        return 1
    fi
    
    # Check if the file contains the expected validator balances
    local count
    count=$(grep -c "\"balance\": *\"0xDE0B6B3A7640000\"" "$TEST_DIR/genesis.json" || echo "0")
    if [ "$count" -ne 4 ]; then
        echo "Expected 4 validator balances, found $count"
        return 1
    fi
    
    return 0
}

# Test 5: Check if script handles missing keys gracefully
test_missing_keys() {
    local temp_dir=$(mktemp -d)
    if ! MOCK_MODE=true BASE_DIR="$temp_dir" "$SCRIPT_PATH" 2>&1 | grep -q "Error: Key file.*does not exist"; then
        echo "Missing key error not detected"
        rm -rf "$temp_dir"
        return 1
    fi
    rm -rf "$temp_dir"
    return 0
}

# Test 6: Check if script handles different number of validators
test_different_validator_count() {
    # Create a test directory with 2 validators
    local temp_dir=$(mktemp -d)
    mkdir -p "$temp_dir/validator1" "$temp_dir/validator2"
    openssl rand -hex 32 > "$temp_dir/validator1/key"
    openssl rand -hex 32 > "$temp_dir/validator2/key"
    
    # Run the script with 2 validators
    MOCK_MODE=true BASE_DIR="$temp_dir" NUM_VALIDATORS=2 "$SCRIPT_PATH" > /dev/null 2>&1
    
    # Check if the files contain the expected number of validators
    local count
    count=$(grep -c '"name": *"validator' "$temp_dir/validator_info.json" || echo "0")
    if [ "$count" -ne 2 ]; then
        echo "Expected 2 validators, found $count"
        rm -rf "$temp_dir"
        return 1
    fi
    
    count=$(grep -c "enode://" "$temp_dir/static-nodes.json" || echo "0")
    if [ "$count" -ne 2 ]; then
        echo "Expected 2 enode URLs, found $count"
        rm -rf "$temp_dir"
        return 1
    fi
    
    count=$(grep -c "\"balance\": *\"0xDE0B6B3A7640000\"" "$temp_dir/genesis.json" || echo "0")
    if [ "$count" -ne 2 ]; then
        echo "Expected 2 validator balances, found $count"
        rm -rf "$temp_dir"
        return 1
    fi
    
    rm -rf "$temp_dir"
    return 0
}

# Run all tests
echo "Starting tests..."
setup

run_test "Script exists and is executable" "test_script_exists"
run_test "Generates validator_info.json" "test_validator_info_json"
run_test "Generates static-nodes.json" "test_static_nodes_json"
run_test "Generates genesis.json" "test_genesis_json"
run_test "Handles missing keys" "test_missing_keys"
run_test "Handles different validator counts" "test_different_validator_count"

# Clean up
rm -rf "$TEST_DIR"

# Print summary
echo "Test Summary: $PASSED_TESTS/$TOTAL_TESTS tests passed"
if [ "$PASSED_TESTS" -eq "$TOTAL_TESTS" ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi 