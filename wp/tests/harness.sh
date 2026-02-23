#!/usr/bin/env bash
# harness.sh - Test helper library for wp kanban tests
# Source this file in test scripts to use assertion functions

# Global counters
TESTS_PASSED=0
TESTS_FAILED=0

# assert_eq
# Usage: assert_eq DESCRIPTION EXPECTED ACTUAL
# Prints PASS: DESCRIPTION if EXPECTED == ACTUAL
# Prints FAIL: DESCRIPTION with a diff if they differ
# Increments global counters TESTS_PASSED and TESTS_FAILED
assert_eq() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        echo "PASS: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "FAIL: $description"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# assert_contains
# Usage: assert_contains DESCRIPTION HAYSTACK NEEDLE
# Passes if NEEDLE is a substring of HAYSTACK
assert_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "PASS: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "FAIL: $description"
        echo "  Expected '$haystack' to contain '$needle'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# assert_exit_code
# Usage: assert_exit_code DESCRIPTION EXPECTED_CODE ACTUAL_CODE
# Passes if exit codes match
assert_exit_code() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    
    if [[ "$expected" -eq "$actual" ]]; then
        echo "PASS: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "FAIL: $description"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code:   $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# report
# Prints summary: Results: X passed, Y failed
# Exits with code 0 if all passed, 1 if any failed
report() {
    echo ""
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}
