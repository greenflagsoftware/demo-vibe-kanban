#!/usr/bin/env bash
set -euo pipefail

# test-foundation.sh - Tests for the foundation layer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WP_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the test harness
source "$SCRIPT_DIR/harness.sh"

# Source the common library
source "$WP_ROOT/lib/wp-common.sh"

# Test directory for isolated tests
TEST_SESSION_DIR=""

# Setup: create a temporary test session directory
setup_test_session() {
    TEST_SESSION_DIR=$(mktemp -d)
    export WP_SESSION="$TEST_SESSION_DIR"
}

# Teardown: remove temporary test session directory
teardown_test_session() {
    if [[ -n "$TEST_SESSION_DIR" ]] && [[ -d "$TEST_SESSION_DIR" ]]; then
        rm -rf "$TEST_SESSION_DIR"
    fi
    unset WP_SESSION
}

# Create a test input file
create_test_file() {
    local content="${1:-Hello World}"
    local file
    file=$(mktemp)
    echo "$content" > "$file"
    echo "$file"
}

# Test: wp init creates expected directory structure
test_init_creates_structure() {
    setup_test_session
    
    local test_file
    test_file=$(create_test_file "Test content")
    
    "$WP_ROOT/bin/wp" init "$test_file"
    
    # Check directories exist
    if [[ -d "$TEST_SESSION_DIR" ]]; then
        assert_eq "Session directory created" "true" "true"
    else
        assert_eq "Session directory created" "true" "false"
    fi
    
    if [[ -d "$TEST_SESSION_DIR/history" ]]; then
        assert_eq "History directory created" "true" "true"
    else
        assert_eq "History directory created" "true" "false"
    fi
    
    # Check snapshot file exists
    if [[ -f "$TEST_SESSION_DIR/history/0001.txt" ]]; then
        assert_eq "First snapshot created" "true" "true"
    else
        assert_eq "First snapshot created" "true" "false"
    fi
    
    # Check current symlink exists
    if [[ -L "$TEST_SESSION_DIR/current" ]]; then
        assert_eq "Current symlink created" "true" "true"
    else
        assert_eq "Current symlink created" "true" "false"
    fi
    
    # Check meta file exists
    if [[ -f "$TEST_SESSION_DIR/meta" ]]; then
        assert_eq "Meta file created" "true" "true"
    else
        assert_eq "Meta file created" "true" "false"
    fi
    
    teardown_test_session
    rm -f "$test_file"
}

# Test: wp_commit increments sequence correctly
test_commit_increments_sequence() {
    setup_test_session
    
    local test_file
    test_file=$(create_test_file "Initial content")
    
    "$WP_ROOT/bin/wp" init "$test_file"
    
    # Initial sequence should be 1
    local seq
    seq=$(wp_seq)
    assert_eq "Initial sequence is 1" "1" "$seq"
    
    # Commit a new snapshot
    echo "Second content" | wp_commit
    
    seq=$(wp_seq)
    assert_eq "Sequence after commit is 2" "2" "$seq"
    
    # Commit another
    echo "Third content" | wp_commit
    
    seq=$(wp_seq)
    assert_eq "Sequence after second commit is 3" "3" "$seq"
    
    teardown_test_session
    rm -f "$test_file"
}

# Test: wp_current fails gracefully when no session exists
test_current_fails_without_session() {
    setup_test_session
    
    # Ensure no session exists
    local exit_code=0
    (wp_current 2>/dev/null) || exit_code=$?
    
    assert_exit_code "wp_current exits 1 without session" "1" "$exit_code"
    
    teardown_test_session
}

# Test: wp save writes the correct content
test_save_writes_content() {
    setup_test_session
    
    local test_file
    test_file=$(create_test_file "Save test content")
    
    "$WP_ROOT/bin/wp" init "$test_file"
    
    local output_file
    output_file=$(mktemp)
    
    "$WP_ROOT/bin/wp" save "$output_file"
    
    local saved_content
    saved_content=$(cat "$output_file")
    
    assert_eq "Saved content matches original" "Save test content" "$saved_content"
    
    teardown_test_session
    rm -f "$test_file" "$output_file"
}

# Test: wp clean removes the session directory
test_clean_removes_session() {
    setup_test_session
    
    local test_file
    test_file=$(create_test_file "Clean test")
    
    "$WP_ROOT/bin/wp" init "$test_file"
    
    # Verify session exists
    if [[ -d "$TEST_SESSION_DIR" ]]; then
        assert_eq "Session exists before clean" "true" "true"
    else
        assert_eq "Session exists before clean" "true" "false"
    fi
    
    # Run clean with automatic confirmation (simulate 'y' input)
    # Use printf to avoid trailing newline issues
    printf 'y\n' | "$WP_ROOT/bin/wp" clean 2>/dev/null
    
    # Verify session is removed
    if [[ ! -d "$TEST_SESSION_DIR" ]]; then
        assert_eq "Session removed after clean" "true" "true"
    else
        assert_eq "Session removed after clean" "true" "false"
    fi
    
    teardown_test_session
    rm -f "$test_file"
}

# Test: wp init fails with non-existent file
test_init_fails_with_nonexistent_file() {
    setup_test_session
    
    local exit_code=0
    "$WP_ROOT/bin/wp" init "/nonexistent/file.txt" 2>/dev/null || exit_code=$?
    
    assert_exit_code "wp init fails with non-existent file" "1" "$exit_code"
    
    teardown_test_session
}

# Test: wp pipe outputs current content
test_pipe_outputs_content() {
    setup_test_session
    
    local test_file
    test_file=$(create_test_file "Pipe test content")
    
    "$WP_ROOT/bin/wp" init "$test_file"
    
    local output
    output=$("$WP_ROOT/bin/wp" pipe)
    
    assert_eq "wp pipe outputs content" "Pipe test content" "$output"
    
    teardown_test_session
    rm -f "$test_file"
}

# Test: wp status shows correct info
test_status_shows_info() {
    setup_test_session
    
    local test_file
    test_file=$(create_test_file "Status test content here")
    
    "$WP_ROOT/bin/wp" init "$test_file"
    
    local output
    output=$("$WP_ROOT/bin/wp" status)
    
    assert_contains "Status shows word count" "$output" "Word count:"
    assert_contains "Status shows snapshot" "$output" "Snapshot:"
    assert_contains "Status shows source" "$output" "Source:"
    
    teardown_test_session
    rm -f "$test_file"
}

# Run all tests
main() {
    echo "Running foundation tests..."
    echo ""
    
    test_init_creates_structure
    test_commit_increments_sequence
    test_current_fails_without_session
    test_save_writes_content
    test_clean_removes_session
    test_init_fails_with_nonexistent_file
    test_pipe_outputs_content
    test_status_shows_info
    
    report
}

main "$@"
