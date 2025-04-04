#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test directory
TEST_DIR="test_besu_compose"
SCRIPT_PATH="./extract_validator_info.sh"
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

# Test 2: Check if script generates valid JSON output
test_json_output() {
    MOCK_MODE=true BASE_DIR="$TEST_DIR" "$SCRIPT_PATH" > /dev/null 2>&1
    if [ ! -f "$TEST_DIR/validator_info.json" ]; then
        echo "validator_info.json not found"
        return 1
    fi
    
    # Try to parse the JSON file
    if command -v jq &> /dev/null; then
        if ! jq '.' "$TEST_DIR/validator_info.json" > /dev/null 2>&1; then
            echo "Invalid JSON format"
            return 1
        fi
    else
        # Basic JSON validation if jq is not available
        if ! grep -q "^\[" "$TEST_DIR/validator_info.json" || \
           ! grep -q "\]$" "$TEST_DIR/validator_info.json" || \
           ! grep -q '"name":' "$TEST_DIR/validator_info.json" || \
           ! grep -q '"address":' "$TEST_DIR/validator_info.json" || \
           ! grep -q '"enode":' "$TEST_DIR/validator_info.json"; then
            echo "Invalid JSON structure"
            return 1
        fi
    fi
    return 0
}

# Test 3: Check if addresses are valid Ethereum addresses
test_ethereum_addresses() {
    MOCK_MODE=true BASE_DIR="$TEST_DIR" "$SCRIPT_PATH" > /dev/null 2>&1
    if ! grep -q '"address": *"0x[a-fA-F0-9]\{40\}"' "$TEST_DIR/validator_info.json"; then
        echo "Invalid Ethereum address format"
        cat "$TEST_DIR/validator_info.json"
        return 1
    fi
    return 0
}

# Test 4: Check if enode URLs are properly formatted
test_enode_urls() {
    MOCK_MODE=true BASE_DIR="$TEST_DIR" "$SCRIPT_PATH" > /dev/null 2>&1
    if ! grep -q '"enode": *"enode://[a-fA-F0-9]\{128\}@127\.0\.0\.1:3030[3-6]"' "$TEST_DIR/validator_info.json"; then
        echo "Invalid enode URL format"
        cat "$TEST_DIR/validator_info.json"
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
test_validator_count() {
    MOCK_MODE=true BASE_DIR="$TEST_DIR" "$SCRIPT_PATH" 2 > /dev/null 2>&1
    local count
    count=$(grep -c '"name": *"validator' "$TEST_DIR/validator_info.json" || echo "0")
    if [ "$count" -ne 2 ]; then
        echo "Expected 2 validators, found $count"
        cat "$TEST_DIR/validator_info.json"
        return 1
    fi
    return 0
}

# Run all tests
echo "Starting tests..."
setup

run_test "Script exists and is executable" "test_script_exists"
run_test "Generates valid JSON output" "test_json_output"
run_test "Valid Ethereum addresses" "test_ethereum_addresses"
run_test "Valid enode URLs" "test_enode_urls"
run_test "Handles missing keys" "test_missing_keys"
run_test "Handles different validator counts" "test_validator_count"

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