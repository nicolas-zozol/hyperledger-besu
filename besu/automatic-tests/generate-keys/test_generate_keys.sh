#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test directory
TEST_DIR="../../besu-compose-test"
SCRIPT_PATH="./generate_validator_keys.sh"

# Function to check if a file exists and has correct format
check_key_file() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: Key file $file does not exist${NC}"
        return 1
    fi
    
    # Check if file contains a 32-byte hex string (64 characters)
    local content=$(cat "$file")
    if [[ ! "$content" =~ ^[0-9a-f]{64}$ ]]; then
        echo -e "${RED}Error: Key file $file does not contain a valid 32-byte hex string${NC}"
        return 1
    fi
    
    return 0
}

# Function to run tests
run_test() {
    local num_validators=$1
    local test_name=$2
    
    echo "Running test: $test_name"
    
    # Clean up previous test directory if it exists
    rm -rf "$TEST_DIR"
    
    # Run the script with specified number of validators
    BASE_DIR="$TEST_DIR" $SCRIPT_PATH "$num_validators"
    
    # Check if all directories and files were created
    local success=true
    for i in $(seq 1 $num_validators); do
        if [ ! -d "$TEST_DIR/validator$i" ]; then
            echo -e "${RED}Error: Directory validator$i was not created${NC}"
            success=false
        fi
        
        if [ ! -d "$TEST_DIR/validator$i/data" ]; then
            echo -e "${RED}Error: Data directory for validator$i was not created${NC}"
            success=false
        fi
        
        if ! check_key_file "$TEST_DIR/validator$i/key"; then
            success=false
        fi
    done
    
    if [ "$success" = true ]; then
        echo -e "${GREEN}Test passed: $test_name${NC}"
        return 0
    else
        echo -e "${RED}Test failed: $test_name${NC}"
        return 1
    fi
}

# Make the script executable
chmod +x "$SCRIPT_PATH"

# Run tests
total_tests=0
passed_tests=0

# Test with default number of validators (4)
((total_tests++))
if run_test 4 "Default number of validators"; then
    ((passed_tests++))
fi

# Test with custom number of validators (2)
((total_tests++))
if run_test 2 "Custom number of validators"; then
    ((passed_tests++))
fi

# Test with larger number of validators (6)
((total_tests++))
if run_test 6 "Larger number of validators"; then
    ((passed_tests++))
fi

# Clean up
rm -rf "$TEST_DIR"

# Print summary
echo "Test Summary: $passed_tests/$total_tests tests passed"
if [ "$passed_tests" -eq "$total_tests" ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi 