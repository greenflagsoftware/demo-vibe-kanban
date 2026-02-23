#!/usr/bin/env bash
# test-search.sh - Tests for wp-search

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WP_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the test harness
source "$SCRIPT_DIR/harness.sh"

# Source wp-common for helper functions
source "$SCRIPT_DIR/../lib/wp-common.sh"

# Setup: create a temporary session directory for each test
setup_session() {
    export WP_SESSION=$(mktemp -d)
}

# Teardown: remove the temporary session directory
teardown_session() {
    if [[ -n "${WP_SESSION:-}" ]]; then
        rm -rf "$WP_SESSION"
    fi
}

# Initialize a session with given content
init_session_with_content() {
    local content="$1"
    local session_dir
    session_dir="$(wp_session_dir)"
    local history_dir="$session_dir/history"
    local meta_file="$session_dir/meta"
    local current_link="$session_dir/current"
    
    mkdir -p "$history_dir"
    
    local snapshot_file="$history_dir/0001.txt"
    echo "$content" > "$snapshot_file"
    ln -sf "$snapshot_file" "$current_link"
    
    {
        echo "seq=0001"
        echo "source=test"
    } > "$meta_file"
}

# Test 1: Simple literal replace
test_simple_literal_replace() {
    setup_session
    init_session_with_content "the cat sat on the mat"
    
    local result
    result=$(echo "the cat sat on the mat" | "$WP_ROOT/bin/wp-search" "cat" "dog")
    
    assert_eq "Simple literal replace" "the dog sat on the mat" "$result"
    
    teardown_session
}

# Test 2: Case-insensitive -i flag
test_case_insensitive() {
    setup_session
    init_session_with_content "Cat cat CAT"
    
    local result
    result=$(echo "Cat cat CAT" | "$WP_ROOT/bin/wp-search" -i "cat" "dog")
    
    assert_eq "Case-insensitive replace" "dog dog dog" "$result"
    
    teardown_session
}

# Test 3: ERE pattern -r flag
test_ere_pattern() {
    setup_session
    init_session_with_content "Mr. Smith and Mrs. Jones"
    
    local result
    result=$(echo "Mr. Smith and Mrs. Jones" | "$WP_ROOT/bin/wp-search" -r '(Mr|Mrs)\.' 'Mx.')
    
    assert_eq "ERE pattern replace" "Mx. Smith and Mx. Jones" "$result"
    
    teardown_session
}

# Test 4: -n 2 flag (replace only 2nd occurrence)
test_nth_occurrence() {
    setup_session
    init_session_with_content "a b a b a"
    
    local result
    result=$(echo "a b a b a" | "$WP_ROOT/bin/wp-search" -n 2 "a" "X")
    
    assert_eq "Nth occurrence (2nd) replace" "a b X b a" "$result"
    
    teardown_session
}

# Test 5: Preview mode -p (show diff, no commit)
test_preview_mode() {
    setup_session
    init_session_with_content "hello world"
    
    local seq_before
    seq_before=$(wp_seq)
    
    local result
    result=$(echo "hello world" | "$WP_ROOT/bin/wp-search" -p "world" "there" 2>&1) || true
    
    # Check that output contains diff markers
    assert_contains "Preview mode shows diff" "$result" "world"
    
    # Sequence should be unchanged
    local seq_after
    seq_after=$(wp_seq)
    assert_eq "Preview mode does not increment seq" "$seq_before" "$seq_after"
    
    teardown_session
}

# Test 6: Pattern with / character
test_pattern_with_slash() {
    setup_session
    init_session_with_content "path/to/file"
    
    local result
    result=$(echo "path/to/file" | "$WP_ROOT/bin/wp-search" "path/to" "new/path")
    
    assert_eq "Pattern with slash" "new/path/file" "$result"
    
    teardown_session
}

# Test 7: No match (input passes through unchanged)
test_no_match() {
    setup_session
    init_session_with_content "hello world"
    
    local result
    result=$(echo "hello world" | "$WP_ROOT/bin/wp-search" "xyz" "abc")
    
    assert_eq "No match passes through unchanged" "hello world" "$result"
    
    teardown_session
}

# Test 8: Empty input
test_empty_input() {
    setup_session
    init_session_with_content ""
    
    local result
    result=$(echo -n "" | "$WP_ROOT/bin/wp-search" "cat" "dog")
    
    assert_eq "Empty input produces empty output" "" "$result"
    
    teardown_session
}

# Test 9: Verify seq increments after non-preview run
test_seq_increments() {
    setup_session
    init_session_with_content "test content"
    
    local seq_before
    seq_before=$(wp_seq)
    
    echo "test content" | "$WP_ROOT/bin/wp-search" "test" "modified" > /dev/null
    
    local seq_after
    seq_after=$(wp_seq)
    
    local expected_after=$((seq_before + 1))
    assert_eq "Seq increments after commit" "$expected_after" "$seq_after"
    
    teardown_session
}

# Test 10: Error handling - missing arguments
test_missing_arguments() {
    setup_session
    
    local exit_code=0
    "$WP_ROOT/bin/wp-search" 2>/dev/null || exit_code=$?
    
    assert_eq "Missing arguments exits with 1" "1" "$exit_code"
    
    teardown_session
}

# Run all tests
test_simple_literal_replace
test_case_insensitive
test_ere_pattern
test_nth_occurrence
test_preview_mode
test_pattern_with_slash
test_no_match
test_empty_input
test_seq_increments
test_missing_arguments

# Report results
report
